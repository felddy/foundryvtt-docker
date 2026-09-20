"""Unit tests for src/cache_prune.sh.

Fixture archives get staggered mtimes via os.utime, then cache_prune is
driven through a bash subprocess with logging stubbed out, matching the
harness used by the other shell-library tests.
"""

# Standard Python Libraries
import os
from pathlib import Path
import subprocess
import textwrap
import time

SRC_DIR = Path(__file__).parent.parent / "src"

LOG_STUBS = textwrap.dedent("""\
    log()       { :; }
    log_debug() { :; }
    log_warn()  { :; }
    log_error() { :; }
""")


def _run(cache_dir: Path, keep: int) -> subprocess.CompletedProcess:
    script = (
        f"cd '{SRC_DIR}'\n"
        f"{LOG_STUBS}\n"
        "source cache_prune.sh\n"
        f"cache_prune '{cache_dir}' {keep}\n"
    )
    return subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True, timeout=10
    )


def _make(cache_dir: Path, name: str, used_ago_s: int) -> Path:
    f = cache_dir / name
    f.write_bytes(b"zip")
    stamp = time.time() - used_ago_s
    os.utime(f, (stamp, stamp))
    return f


def test_evicts_least_recently_used_not_lowest_version(tmp_path: Path) -> None:
    """The #1266 scenario: a recently used v12 outlives never-used v13 zips.

    Version-sorted eviction would delete 12.343 first; LRU keeps it because
    an instance still installs from it.
    """
    _make(tmp_path, "foundryvtt-12.343.zip", used_ago_s=60)  # used today
    _make(tmp_path, "foundryvtt-13.345.zip", used_ago_s=4000)
    _make(tmp_path, "foundryvtt-13.346.zip", used_ago_s=3000)
    _make(tmp_path, "foundryvtt-13.347.zip", used_ago_s=2000)

    result = _run(tmp_path, keep=2)
    assert result.returncode == 0, result.stderr

    survivors = sorted(p.name for p in tmp_path.glob("foundryvtt-*.zip"))
    assert survivors == ["foundryvtt-12.343.zip", "foundryvtt-13.347.zip"]


def test_keep_count_at_or_above_total_removes_nothing(tmp_path: Path) -> None:
    """No eviction when the cache is within the limit."""
    _make(tmp_path, "foundryvtt-13.345.zip", used_ago_s=100)
    _make(tmp_path, "foundryvtt-13.346.zip", used_ago_s=50)

    result = _run(tmp_path, keep=2)
    assert result.returncode == 0, result.stderr
    assert len(list(tmp_path.glob("foundryvtt-*.zip"))) == 2


def test_only_release_archives_are_considered(tmp_path: Path) -> None:
    """Temp downloads, state files, and lock dirs are never counted or removed."""
    _make(tmp_path, "foundryvtt-13.346.zip", used_ago_s=100)
    _make(tmp_path, "foundryvtt-13.347.zip", used_ago_s=50)
    (tmp_path / "downloading-13.348.host-1.zip").write_bytes(b"partial")
    (tmp_path / "backoff_state.json").write_text("{}")
    (tmp_path / "foundryvtt-13.348.zip.lock").mkdir()

    result = _run(tmp_path, keep=1)
    assert result.returncode == 0, result.stderr

    assert not (tmp_path / "foundryvtt-13.346.zip").exists()  # evicted (older)
    assert (tmp_path / "foundryvtt-13.347.zip").exists()
    assert (tmp_path / "downloading-13.348.host-1.zip").exists()
    assert (tmp_path / "backoff_state.json").exists()
    assert (tmp_path / "foundryvtt-13.348.zip.lock").is_dir()


def test_empty_cache_is_a_noop(tmp_path: Path) -> None:
    """An empty (or missing) cache directory prunes cleanly."""
    result = _run(tmp_path, keep=3)
    assert result.returncode == 0, result.stderr
    result = _run(tmp_path / "missing", keep=3)
    assert result.returncode == 0, result.stderr
