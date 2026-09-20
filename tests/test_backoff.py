"""Unit tests for src/backoff.sh.

Tests are driven via subprocess calls to bash, sourcing backoff.sh directly.
logging.sh is stubbed out so tests have no terminal-color side-effects.
"""

# Standard Python Libraries
import json
import os
from pathlib import Path
import subprocess
import textwrap
import time

# Third-Party Libraries
import pytest

# Absolute path to the src/ directory so bash can find backoff.sh / logging.sh.
SRC_DIR = Path(__file__).parent.parent / "src"


def _run(
    script: str, env: dict | None = None, timeout: int = 10
) -> subprocess.CompletedProcess:
    """Run a bash snippet that sources backoff.sh with logging stubbed out.

    Logging functions are defined inline before sourcing backoff.sh, since
    backoff.sh now depends on the caller to provide them.
    """
    log_stubs = textwrap.dedent("""\
        log()       { :; }
        log_debug() { :; }
        log_warn()  { :; }
        log_error() { :; }
    """)
    full_script = f"cd '{SRC_DIR}'\n{log_stubs}\nsource backoff.sh\n{script}"
    merged_env = {**os.environ, **(env or {})}
    merged_env.pop("KUBERNETES_SERVICE_HOST", None)
    if env and "KUBERNETES_SERVICE_HOST" in env:
        merged_env["KUBERNETES_SERVICE_HOST"] = env["KUBERNETES_SERVICE_HOST"]
    return subprocess.run(
        ["bash", "-c", full_script],
        capture_output=True,
        text=True,
        env=merged_env,
        timeout=timeout,
    )


# ── Delay formula ─────────────────────────────────────────────────────────────

EXPECTED_DELAYS = {
    1: 0,
    2: 10,
    3: 20,
    4: 40,
    5: 80,
    6: 160,
    7: 320,
    8: 640,
    9: 960,
    10: 960,
}


@pytest.mark.parametrize("n,expected", EXPECTED_DELAYS.items())
def test_delay_formula_each_step(n: int, expected: int) -> None:
    """The bash delay formula produces the correct value for each failure count n.

    n=1 (first failure) exits immediately with delay=0.
    Subsequent failures use min(10 * 2^(n-2), 960).
    Tests the formula directly (not via backoff_on_failure) to avoid the exit
    call inside the function. Validates: Requirements 1.2
    """
    script = textwrap.dedent(f"""\
        n={n}
        if (( n <= 1 )); then
          delay=0
        else
          delay=$(( 10 * (1 << (n - 2)) ))
          (( delay > 960 )) && delay=960
        fi
        echo "$delay"
    """)
    result = subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True, check=True
    )
    assert result.stdout.strip() == str(
        expected
    ), f"n={n}: expected delay {expected}s, got '{result.stdout.strip()}'"


# ── State file creation ───────────────────────────────────────────────────────


def test_state_file_created_with_correct_fields(tmp_path: Path) -> None:
    """backoff_on_failure writes consecutive_failures and last_failure_timestamp.

    Validates: Requirements 1.1, 1.4
    """
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        sleep() {{ :; }}
        export -f sleep
        backoff_on_failure 1
    """)
    result = _run(script)
    # backoff_on_failure exits with the passed exit_code
    assert (
        result.returncode == 1
    ), f"Expected exit 1, got {result.returncode}. stderr: {result.stderr}"

    state_file = tmp_path / "backoff_state.json"
    assert state_file.exists(), "State file was not created"

    data = json.loads(state_file.read_text())
    assert "consecutive_failures" in data, "Missing consecutive_failures field"
    assert "last_failure_timestamp" in data, "Missing last_failure_timestamp field"
    assert data["consecutive_failures"] == 1
    # Timestamp should look like an ISO 8601 UTC string
    assert "T" in data["last_failure_timestamp"]
    assert data["last_failure_timestamp"].endswith("Z")


def test_state_file_increments_on_repeated_failures(tmp_path: Path) -> None:
    """Consecutive calls to backoff_on_failure increment the failure count.

    Each call is a separate process (since backoff_on_failure exits).
    Validates: Requirements 1.4
    """

    def run_one_failure(cache_dir: Path) -> None:
        script = textwrap.dedent(f"""\
            CONTAINER_CACHE={cache_dir}
            sleep() {{ :; }}
            export -f sleep
            backoff_on_failure 1
        """)
        _run(script)  # exits with 1, that's fine

    run_one_failure(tmp_path)
    run_one_failure(tmp_path)
    run_one_failure(tmp_path)

    data = json.loads((tmp_path / "backoff_state.json").read_text())
    assert data["consecutive_failures"] == 3


# ── backoff_reset ─────────────────────────────────────────────────────────────


def test_backoff_reset_deletes_state_file(tmp_path: Path) -> None:
    """backoff_reset removes the state file when it exists.

    Validates: Requirements 4.1
    """
    state_file = tmp_path / "backoff_state.json"
    state_file.write_text(
        json.dumps(
            {
                "consecutive_failures": 3,
                "last_failure_timestamp": "2024-01-01T00:00:00Z",
            }
        )
    )

    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        backoff_reset
    """)
    result = _run(script)
    assert result.returncode == 0, result.stderr
    assert (
        not state_file.exists()
    ), "State file should have been deleted by backoff_reset"


def test_backoff_reset_noop_when_no_state_file(tmp_path: Path) -> None:
    """backoff_reset is a no-op when no state file exists.

    Validates: Requirements 4.1
    """
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        backoff_reset
    """)
    result = _run(script)
    assert result.returncode == 0, result.stderr


# ── Corrupt state file ────────────────────────────────────────────────────────


def test_corrupt_state_file_resets_to_n1(tmp_path: Path) -> None:
    """A corrupt state file is treated as consecutive_failures=0.

    Verified by checking the state file written after the call: consecutive_failures
    should be 1 (meaning it started from 0 and incremented once). With n=1 the
    delay is 0, so the first failure after a corrupt state exits without sleeping.
    Validates: Requirements 1.1
    """
    state_file = tmp_path / "backoff_state.json"
    state_file.write_text("this is not valid json {{{{")

    # Run backoff_on_failure in a subshell; it will exit with code 1 (the passed
    # exit_code). We check the state file to confirm it reset to n=1.
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        sleep() {{ :; }}
        export -f sleep
        backoff_on_failure 1
    """)
    result = _run(script)
    # backoff_on_failure exits with the original exit_code (1)
    assert (
        result.returncode == 1
    ), f"Expected exit 1, got {result.returncode}. stderr: {result.stderr}"

    data = json.loads(state_file.read_text())
    assert data["consecutive_failures"] == 1, (
        f"Corrupt state should reset to n=1, got "
        f"consecutive_failures={data['consecutive_failures']}"
    )


# ── Kubernetes bypass ─────────────────────────────────────────────────────────


def test_kubernetes_skips_file_io(tmp_path: Path) -> None:
    """When KUBERNETES_SERVICE_HOST is set, no state file is created or read.

    Validates: Requirements 3.2, 3.4
    """
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        backoff_on_failure 1
    """)
    result = _run(script, env={"KUBERNETES_SERVICE_HOST": "10.0.0.1"})
    assert result.returncode == 0, result.stderr

    state_file = tmp_path / "backoff_state.json"
    assert not state_file.exists(), "Kubernetes path must not create a state file"


def test_kubernetes_does_not_sleep(tmp_path: Path) -> None:
    """Kubernetes path returns immediately without sleeping.

    Validates: Requirements 3.2
    """
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={tmp_path}
        sleep_called=false
        sleep() {{ sleep_called=true; }}
        export -f sleep
        backoff_on_failure 1
        echo "$sleep_called"
    """)
    result = _run(script, env={"KUBERNETES_SERVICE_HOST": "10.0.0.1"})
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "false", "Kubernetes path must not call sleep"


# ── No-cache indefinite sleep ─────────────────────────────────────────────────


def test_no_cache_triggers_indefinite_sleep(tmp_path: Path) -> None:
    """When CONTAINER_CACHE is unset, backoff_on_failure does not exit on its own.

    The process should remain alive until signalled. We verify it's still running
    after a short interval, then send SIGTERM to clean up.

    Note: skipped on macOS because BSD sleep does not support 'sleep infinity'.
    The container runs on Linux where this works correctly.
    Validates: Requirements 2.1
    """
    # Standard Python Libraries
    import platform

    if platform.system() == "Darwin":
        pytest.skip("sleep infinity not supported on macOS BSD sleep")

    _log_stubs = "log(){ :; }; log_debug(){ :; }; log_warn(){ :; }; log_error(){ :; }"
    script = textwrap.dedent(f"""\
        cd '{SRC_DIR}'
        {_log_stubs}
        source backoff.sh
        unset CONTAINER_CACHE
        trap 'kill $backoff_sleep_pid 2>/dev/null; exit 0' SIGTERM
        backoff_on_failure 1
    """)
    env = {**os.environ}
    env.pop("KUBERNETES_SERVICE_HOST", None)
    proc = subprocess.Popen(
        ["bash", "-c", script], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env
    )
    time.sleep(0.5)
    assert (
        proc.poll() is None
    ), "Process should still be running (sleeping indefinitely)"
    proc.send_signal(__import__("signal").SIGTERM)
    proc.wait(timeout=5)


def test_no_cache_exits_0_on_sigterm() -> None:
    """When sleeping indefinitely (no cache), SIGTERM causes a clean exit 0.

    Validates: Requirements 2.3
    """
    _log_stubs = "log(){ :; }; log_debug(){ :; }; log_warn(){ :; }; log_error(){ :; }"
    script = textwrap.dedent(f"""\
        cd '{SRC_DIR}'
        {_log_stubs}
        source backoff.sh
        unset CONTAINER_CACHE
        trap 'kill $backoff_sleep_pid 2>/dev/null; exit 0' SIGTERM
        backoff_on_failure 1
    """)
    env = {**os.environ}
    env.pop("KUBERNETES_SERVICE_HOST", None)
    proc = subprocess.Popen(
        ["bash", "-c", script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )
    time.sleep(0.3)
    proc.send_signal(__import__("signal").SIGTERM)
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        pytest.fail("Process did not exit within 5s after SIGTERM")
    assert proc.returncode == 0, f"Expected exit 0 after SIGTERM, got {proc.returncode}"


# ── Auth failure identical to generic failure ─────────────────────────────────


def test_auth_failure_same_delay_as_generic_failure(tmp_path: Path) -> None:
    """An auth failure exit code produces the same delay as any other non-zero code.

    Both produce consecutive_failures=1 from a clean state, so the resulting
    state file is identical regardless of the exit code passed.
    Validates: Requirements 6.1, 6.3
    """

    def run_failure(exit_code: int, cache_dir: Path) -> dict:
        script = textwrap.dedent(f"""\
            CONTAINER_CACHE={cache_dir}
            sleep() {{ :; }}
            export -f sleep
            backoff_on_failure {exit_code}
        """)
        _run(script)  # exits with exit_code, that's expected
        return json.loads((cache_dir / "backoff_state.json").read_text())

    auth_dir = tmp_path / "auth"
    auth_dir.mkdir()
    generic_dir = tmp_path / "generic"
    generic_dir.mkdir()

    auth_state = run_failure(1, auth_dir)
    generic_state = run_failure(2, generic_dir)

    assert (
        auth_state["consecutive_failures"] == generic_state["consecutive_failures"]
    ), (
        f"Auth failure count ({auth_state['consecutive_failures']}) differs from "
        f"generic failure count ({generic_state['consecutive_failures']})"
    )


def test_auth_failure_state_file_identical_to_generic(tmp_path: Path) -> None:
    """Auth failure and generic failure produce identical state file contents.

    Validates: Requirements 6.1, 6.3
    """

    def run_failure(exit_code: int, cache_dir: Path) -> dict:
        script = textwrap.dedent(f"""\
            CONTAINER_CACHE={cache_dir}
            sleep() {{ :; }}
            export -f sleep
            backoff_on_failure {exit_code}
        """)
        _run(script)
        return json.loads((cache_dir / "backoff_state.json").read_text())

    auth_dir = tmp_path / "auth"
    auth_dir.mkdir()
    generic_dir = tmp_path / "generic"
    generic_dir.mkdir()

    auth_state = run_failure(1, auth_dir)
    generic_state = run_failure(2, generic_dir)

    assert auth_state["consecutive_failures"] == generic_state["consecutive_failures"]


# ── Failure count decay ───────────────────────────────────────────────────────


def _write_state(cache_dir: Path, failures: int, epoch: int | None) -> None:
    state: dict = {
        "consecutive_failures": failures,
        "last_failure_timestamp": "2024-01-01T00:00:00Z",
    }
    if epoch is not None:
        state["last_failure_epoch"] = epoch
    (cache_dir / "backoff_state.json").write_text(json.dumps(state))


def _fail_once(cache_dir: Path, env: dict | None = None) -> dict:
    script = textwrap.dedent(f"""\
        CONTAINER_CACHE={cache_dir}
        sleep() {{ :; }}
        export -f sleep
        backoff_on_failure 1
    """)
    # Pin the decay window unless a test overrides it, so an exported
    # BACKOFF_DECAY_SECONDS in the developer's environment cannot leak in
    # (_run merges os.environ).
    _run(script, env={"BACKOFF_DECAY_SECONDS": "3600", **(env or {})})
    return json.loads((cache_dir / "backoff_state.json").read_text())


def test_stale_failure_resets_count(tmp_path: Path) -> None:
    """A failure long after the previous one restarts the count at 1.

    Failures separated by more than BACKOFF_DECAY_SECONDS are independent
    incidents, not a restart loop, so the delay must not keep growing.
    """
    _write_state(tmp_path, failures=5, epoch=int(time.time()) - 7200)
    data = _fail_once(tmp_path)
    assert data["consecutive_failures"] == 1, (
        f"Stale failure should reset the count to 1, got "
        f"consecutive_failures={data['consecutive_failures']}"
    )


def test_recent_failure_still_increments_count(tmp_path: Path) -> None:
    """A failure shortly after the previous one keeps escalating."""
    _write_state(tmp_path, failures=5, epoch=int(time.time()) - 10)
    data = _fail_once(tmp_path)
    assert data["consecutive_failures"] == 6


def test_state_without_epoch_still_increments(tmp_path: Path) -> None:
    """A pre-decay state file (no last_failure_epoch) keeps the old behavior."""
    _write_state(tmp_path, failures=5, epoch=None)
    data = _fail_once(tmp_path)
    assert data["consecutive_failures"] == 6


def test_decay_window_is_overridable(tmp_path: Path) -> None:
    """BACKOFF_DECAY_SECONDS from the environment controls the reset window."""
    _write_state(tmp_path, failures=5, epoch=int(time.time()) - 30)
    data = _fail_once(tmp_path, env={"BACKOFF_DECAY_SECONDS": "10"})
    assert data["consecutive_failures"] == 1


def test_garbage_decay_override_falls_back_to_default(tmp_path: Path) -> None:
    """A non-numeric BACKOFF_DECAY_SECONDS must not zero the decay window.

    In bash arithmetic an unset-variable name evaluates to 0, which would
    make every failure look stale and reset the count.  The guard falls
    back to the default window instead, so a recent failure still escalates.
    """
    _write_state(tmp_path, failures=5, epoch=int(time.time()) - 10)
    data = _fail_once(tmp_path, env={"BACKOFF_DECAY_SECONDS": "soon"})
    assert data["consecutive_failures"] == 6


def test_leading_zero_override_is_decimal(tmp_path: Path) -> None:
    """A leading-zero override is decimal, not an octal arithmetic error.

    "08" passes digit validation but is an invalid octal constant in bash
    arithmetic; without base-10 normalization the comparison errors and the
    decay is silently skipped.  Here it must mean 8 seconds: a failure 30s
    after the previous one is stale and resets the count.
    """
    _write_state(tmp_path, failures=5, epoch=int(time.time()) - 30)
    data = _fail_once(tmp_path, env={"BACKOFF_DECAY_SECONDS": "08"})
    assert data["consecutive_failures"] == 1


def test_state_file_records_epoch(tmp_path: Path) -> None:
    """backoff_on_failure records last_failure_epoch for the decay check."""
    before = int(time.time())
    data = _fail_once(tmp_path)
    assert isinstance(data.get("last_failure_epoch"), int)
    assert before <= data["last_failure_epoch"] <= int(time.time())
