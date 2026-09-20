"""Unit tests for src/download_lock.sh.

Tests drive bash subprocesses that source download_lock.sh directly, with
logging stubbed out.  Timing knobs are shrunk via the DOWNLOAD_LOCK_*
environment variables so the polling scenarios run in well under a second
per test.
"""

# Standard Python Libraries
import os
from pathlib import Path
import subprocess
import textwrap

SRC_DIR = Path(__file__).parent.parent / "src"

LOG_STUBS = textwrap.dedent("""\
    log()       { :; }
    log_debug() { :; }
    log_warn()  { :; }
    log_error() { :; }
""")

FAST = {
    "DOWNLOAD_LOCK_POLL_SECONDS": "0.05",
    "DOWNLOAD_LOCK_STALL_TICKS": "4",
    "DOWNLOAD_LOCK_STEAL_LIMIT": "3",
}


def _run(
    script: str, env: dict | None = None, timeout: int = 15
) -> subprocess.CompletedProcess:
    full_script = f"cd '{SRC_DIR}'\n{LOG_STUBS}\nsource download_lock.sh\n{script}"
    merged_env = {**os.environ, **FAST, **(env or {})}
    return subprocess.run(
        ["bash", "-c", full_script],
        capture_output=True,
        text=True,
        env=merged_env,
        timeout=timeout,
    )


# ── Basic acquire / release ───────────────────────────────────────────────────


def test_acquire_free_lock(tmp_path: Path) -> None:
    """An uncontended slot is acquired and the owner file is written."""
    result = _run(textwrap.dedent(f"""\
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
            cat "{tmp_path}/v.lock/owner"
        """))
    assert "rc=0" in result.stdout, result.stderr
    assert (tmp_path / "v.lock").is_dir()
    assert result.stdout.strip().splitlines()[-1]  # owner id non-empty


def test_release_removes_lock(tmp_path: Path) -> None:
    """download_slot_release removes a held lock and is safe to repeat."""
    result = _run(textwrap.dedent(f"""\
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            download_slot_release
            download_slot_release
            [[ -d "{tmp_path}/v.lock" ]] && echo "still-there" || echo "gone"
        """))
    assert "gone" in result.stdout, result.stderr


def test_release_file_short_circuits(tmp_path: Path) -> None:
    """An existing release file returns 1 without taking the lock."""
    (tmp_path / "release.zip").write_bytes(b"zip")
    result = _run(textwrap.dedent(f"""\
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
        """))
    assert "rc=1" in result.stdout, result.stderr
    assert not (tmp_path / "v.lock").exists()


def test_degraded_when_lock_cannot_be_created(tmp_path: Path) -> None:
    """A read-only cache directory degrades to unarbitrated mode (rc=2)."""
    ro = tmp_path / "ro"
    ro.mkdir()
    ro.chmod(0o555)
    try:
        result = _run(textwrap.dedent(f"""\
                download_slot_acquire "{ro}/v.lock" "{ro}/release.zip" \\
                  "{ro}/downloading-v.*.zip"
                echo "rc=$?"
            """))
        assert "rc=2" in result.stdout, result.stderr
    finally:
        ro.chmod(0o755)


# ── Waiting behavior ──────────────────────────────────────────────────────────


def test_waiter_returns_when_release_appears(tmp_path: Path) -> None:
    """A waiter returns 1 as soon as the holder produces the release file."""
    result = _run(textwrap.dedent(f"""\
            # Simulated holder: keeps the download progressing, then delivers
            # the release and releases the lock.
            mkdir "{tmp_path}/v.lock"
            (
              for i in 1 2 3 4 5 6; do
                echo "chunk" >> "{tmp_path}/downloading-v.other.zip"
                sleep 0.05
              done
              echo "zip" > "{tmp_path}/release.zip"
              rmdir "{tmp_path}/v.lock" 2>/dev/null || rm -rf "{tmp_path}/v.lock"
            ) &
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
            wait
        """))
    assert "rc=1" in result.stdout, result.stderr


def test_waiter_acquires_after_holder_releases_without_release(tmp_path: Path) -> None:
    """If the holder gives up (lock gone, no release), a waiter acquires."""
    result = _run(textwrap.dedent(f"""\
            mkdir "{tmp_path}/v.lock"
            ( sleep 0.2; rm -rf "{tmp_path}/v.lock" ) &
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
            wait
        """))
    assert "rc=0" in result.stdout, result.stderr


def test_progress_prevents_steal(tmp_path: Path) -> None:
    """A slow but progressing download is waited on, never stolen."""
    result = _run(textwrap.dedent(f"""\
            mkdir "{tmp_path}/v.lock"
            (
              # Progress on every poll for well past the stall window, then
              # deliver.  If the waiter stole, the lock dir would vanish
              # before we deliver and the marker below would print.
              for i in $(seq 1 12); do
                echo "chunk" >> "{tmp_path}/downloading-v.other.zip"
                sleep 0.05
              done
              [[ -d "{tmp_path}/v.lock" ]] || echo "LOCK-WAS-STOLEN"
              echo "zip" > "{tmp_path}/release.zip"
              rm -rf "{tmp_path}/v.lock"
            ) &
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
            wait
        """))
    assert "rc=1" in result.stdout, result.stderr
    assert "LOCK-WAS-STOLEN" not in result.stdout


# ── Stale locks ───────────────────────────────────────────────────────────────


def test_stalled_lock_is_stolen_and_acquired(tmp_path: Path) -> None:
    """A lock with no progress behind it is stolen and then acquired."""
    result = _run(textwrap.dedent(f"""\
            mkdir "{tmp_path}/v.lock"
            echo "dead-holder" > "{tmp_path}/v.lock/owner"
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
            cat "{tmp_path}/v.lock/owner"
        """))
    assert "rc=0" in result.stdout, result.stderr
    # The lock was re-created by us, not inherited from the dead holder.
    assert "dead-holder" not in result.stdout.splitlines()[-1]
    # No stale wreckage left behind.
    assert not list(tmp_path.glob("v.lock.stale.*"))


def test_steal_limit_gives_up(tmp_path: Path) -> None:
    """A stalled lock is abandoned once the steal budget is exhausted.

    With a zero budget the first stall hits the limit check directly,
    which keeps the test deterministic (a live adversary that re-creates
    the lock loses the post-steal acquisition race more often than not).
    """
    result = _run(
        textwrap.dedent(f"""\
            mkdir "{tmp_path}/v.lock"
            download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"
            echo "rc=$?"
        """),
        env={"DOWNLOAD_LOCK_STEAL_LIMIT": "0"},
    )
    assert "rc=3" in result.stdout, result.stderr
    # The stalled lock was not stolen: the dead holder's lock is intact.
    assert (tmp_path / "v.lock").is_dir()


def test_errexit_safe(tmp_path: Path) -> None:
    """All return paths are safe under set -e in the caller."""
    (tmp_path / "release.zip").write_bytes(b"zip")
    result = _run(textwrap.dedent(f"""\
            set -e
            if download_slot_acquire "{tmp_path}/v.lock" "{tmp_path}/release.zip" \\
              "{tmp_path}/downloading-v.*.zip"; then
              rc=0
            else
              rc=$?
            fi
            echo "rc=$rc survived"
        """))
    assert "rc=1 survived" in result.stdout, result.stderr
