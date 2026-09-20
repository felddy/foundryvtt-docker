"""Unit tests for src/release_verify.sh.

Fixture archives are built with Python's zipfile in both release layouts
(Node.js: package.json at the root; Linux: under resources/app/), then the
helper is driven through a bash subprocess, matching the harness used by the
other shell-library tests.
"""

# Standard Python Libraries
import json
from pathlib import Path
import subprocess
import zipfile

SRC_DIR = Path(__file__).parent.parent / "src"


def _make_zip(path: Path, member: str, payload: str) -> Path:
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr(member, payload)
    return path


def _release_json(generation: int, build: int) -> str:
    return json.dumps({"release": {"generation": generation, "build": build}})


def _run(archive: Path) -> subprocess.CompletedProcess:
    script = (
        f"cd '{SRC_DIR}'\n"
        "source release_verify.sh\n"
        f"release_archive_version '{archive}'\n"
    )
    return subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True, timeout=10
    )


def test_node_layout(tmp_path: Path) -> None:
    """A Node.js release zip reports generation.build from its root package.json."""
    archive = _make_zip(tmp_path / "node.zip", "package.json", _release_json(12, 331))
    result = _run(archive)
    assert result.returncode == 0, result.stderr
    assert result.stdout == "12.331"


def test_linux_layout(tmp_path: Path) -> None:
    """A Linux release zip reports the version from resources/app/package.json."""
    archive = _make_zip(
        tmp_path / "linux.zip",
        "resources/app/package.json",
        _release_json(13, 351),
    )
    result = _run(archive)
    assert result.returncode == 0, result.stderr
    assert result.stdout == "13.351"


def test_missing_package_json_is_unknown(tmp_path: Path) -> None:
    """A zip without package.json returns 1 (unknown), never a version."""
    archive = _make_zip(tmp_path / "bare.zip", "readme.txt", "hello")
    result = _run(archive)
    assert result.returncode == 1
    assert result.stdout == ""


def test_malformed_json_is_unknown(tmp_path: Path) -> None:
    """Unparseable package.json returns 1 (unknown)."""
    archive = _make_zip(tmp_path / "bad.zip", "package.json", "{not json")
    result = _run(archive)
    assert result.returncode == 1


def test_legacy_layout_is_unknown(tmp_path: Path) -> None:
    """A pre-v9 package.json (version field, no release object) returns 1.

    Partial metadata must never render as a pseudo-version like "null.null".
    """
    archive = _make_zip(
        tmp_path / "legacy.zip", "package.json", json.dumps({"version": "0.7.9"})
    )
    result = _run(archive)
    assert result.returncode == 1
    assert result.stdout == ""


def test_not_a_zip_is_unknown(tmp_path: Path) -> None:
    """A non-zip file returns 1 (unknown) instead of erroring."""
    not_zip = tmp_path / "not.zip"
    not_zip.write_bytes(b"MZ this is not a zip")
    result = _run(not_zip)
    assert result.returncode == 1
