"""Unit tests for src/lifecycle.sh.

Tests are driven via subprocess calls to bash, sourcing lifecycle.sh directly.
logging.sh is stubbed out so tests have no terminal-color side-effects.
"""

# Standard Python Libraries
from pathlib import Path
import select
import signal
import subprocess
import textwrap
import time

# Absolute path to the src/ directory so bash can find lifecycle.sh.
SRC_DIR = Path(__file__).parent.parent / "src"

LOG_STUBS = textwrap.dedent("""\
    log()       { :; }
    log_debug() { :; }
    log_warn()  { :; }
    log_error() { :; }
""")


def _script(body: str) -> str:
    """Wrap a test body with the sourcing preamble for lifecycle.sh."""
    return f"cd '{SRC_DIR}'\n{LOG_STUBS}\nsource lifecycle.sh\n{body}"


def _run(body: str, timeout: int = 10) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", "-c", _script(body)],
        capture_output=True,
        text=True,
        timeout=timeout,
    )


# ── Plain exits are reported faithfully ───────────────────────────────────────


def test_child_clean_exit() -> None:
    """A child that exits 0 yields status 0."""
    result = _run(textwrap.dedent("""\
            bash -c 'exit 0' &
            wait_for_child $! code
            echo "code=$code"
        """))
    assert result.returncode == 0, result.stderr
    assert "code=0" in result.stdout


def test_child_nonzero_exit() -> None:
    """A child's nonzero exit code is reported unchanged."""
    result = _run(textwrap.dedent("""\
            bash -c 'exit 7' &
            wait_for_child $! code
            echo "code=$code"
        """))
    assert result.returncode == 0, result.stderr
    assert "code=7" in result.stdout


def test_child_killed_by_signal() -> None:
    """A signal-killed child reports 128+signal, and the loop terminates."""
    result = _run(textwrap.dedent("""\
            sleep 30 &
            child=$!
            kill -KILL "$child"
            wait_for_child "$child" code
            echo "code=$code"
        """))
    assert result.returncode == 0, result.stderr
    assert "code=137" in result.stdout


# ── errexit interplay ─────────────────────────────────────────────────────────


def test_errexit_survives_nonzero_child() -> None:
    """Report a failing child under `set -e` without aborting the caller.

    Errexit must still be enabled after wait_for_child returns.
    """
    result = _run(textwrap.dedent("""\
            set -e
            bash -c 'exit 3' &
            wait_for_child $! code
            echo "code=$code"
            [[ $- == *e* ]] && echo "errexit=on"
        """))
    assert result.returncode == 0, result.stderr
    assert "code=3" in result.stdout
    assert "errexit=on" in result.stdout


def test_errexit_not_enabled_when_caller_had_it_off() -> None:
    """wait_for_child must not turn errexit ON for callers running without it."""
    result = _run(textwrap.dedent("""\
            set +e
            bash -c 'exit 3' &
            wait_for_child $! code
            [[ $- == *e* ]] && echo "errexit=on" || echo "errexit=off"
        """))
    assert result.returncode == 0, result.stderr
    assert "errexit=off" in result.stdout


# ── The PID 1 shutdown race ───────────────────────────────────────────────────


def test_sigterm_waits_for_slow_child_shutdown() -> None:
    """SIGTERM to the parent must not end the wait before the child finishes.

    Models the container shutdown path: the parent traps TERM and forwards it
    to a child that needs time to clean up (Foundry flushing data).  The
    parent must survive until the child exits and then report the child's
    real exit code — not the 143 from the interrupted `wait`.
    """
    # The decoy sleep gets its stdio detached so the orphan cannot hold the
    # test harness's stdout pipe open after the parent exits.  Both processes
    # announce readiness after installing their TERM traps; the test only
    # signals once both markers have been read, so no fixed delay is needed.
    child_cmd = (
        'trap "sleep 1; echo child-done; exit 5" TERM; echo child-ready; '
        "sleep 30 >/dev/null 2>&1 & wait $!"
    )
    body = textwrap.dedent(f"""\
        set -e
        bash -c '{child_cmd}' &
        child=$!
        trap 'kill -TERM "$child" 2>/dev/null' TERM
        echo parent-ready
        wait_for_child "$child" code
        echo "parent-saw=$code"
        exit "$code"
    """)
    proc = subprocess.Popen(
        ["bash", "-c", _script(body)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    # A TERM that lands between parent-ready and the wait is still safe:
    # traps run at the next command boundary and wait_for_child reaps an
    # already-exited child, so readiness of both traps is all we need.
    stdout_pipe = proc.stdout
    assert stdout_pipe is not None
    pending = {"child-ready", "parent-ready"}
    deadline = time.time() + 10
    while pending:
        remaining = deadline - time.time()
        readable = remaining > 0 and select.select([stdout_pipe], [], [], remaining)[0]
        assert readable, f"timed out waiting for readiness; still missing {pending}"
        pending.discard(stdout_pipe.readline().strip())
    proc.send_signal(signal.SIGTERM)
    stdout, stderr = proc.communicate(timeout=10)
    # The child had time to finish its cleanup and its status was preserved.
    assert "child-done" in stdout, f"stdout: {stdout!r} stderr: {stderr!r}"
    assert "parent-saw=5" in stdout, f"stdout: {stdout!r} stderr: {stderr!r}"
    assert proc.returncode == 5, f"expected 5, got {proc.returncode}"
    # Ordering: the parent only reported after the child was done.
    assert stdout.index("child-done") < stdout.index("parent-saw=5")
