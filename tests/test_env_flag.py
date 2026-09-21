"""Unit tests for src/env_flag.sh.

The helpers are driven through bash subprocesses with logging stubbed to a
recognizable marker, matching the harness used by the other shell-library
tests.
"""

# Standard Python Libraries
import os
from pathlib import Path
import subprocess
import textwrap

# Third-Party Libraries
import pytest

SRC_DIR = Path(__file__).parent.parent / "src"

LOG_STUBS = textwrap.dedent("""\
    log()       { :; }
    log_debug() { :; }
    log_warn()  { echo "WARNED: $*"; }
    log_error() { :; }
""")


def _run(func: str, value: str | None) -> subprocess.CompletedProcess:
    script = (
        f"cd '{SRC_DIR}'\n"
        f"{LOG_STUBS}\n"
        "source env_flag.sh\n"
        f"{func} MY_FLAG && echo yes || echo no\n"
    )
    env = {**os.environ}
    env.pop("MY_FLAG", None)
    if value is not None:
        env["MY_FLAG"] = value
    return subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True, env=env, timeout=10
    )


TRUTHY = ["1", "true", "TRUE", "True", "yes", "YES", "on", "On"]
FALSY = ["0", "false", "FALSE", "False", "no", "No", "off", "OFF"]


@pytest.mark.parametrize("value", TRUTHY)
def test_truthy_values(value: str) -> None:
    """Every documented truthy form is true, case-insensitively."""
    result = _run("env_is_true", value)
    assert "yes" in result.stdout and "WARNED" not in result.stdout


@pytest.mark.parametrize("value", FALSY)
def test_falsy_values(value: str) -> None:
    """Every documented falsy form is false for env_is_true, without warning."""
    result = _run("env_is_true", value)
    assert "no" in result.stdout and "WARNED" not in result.stdout


@pytest.mark.parametrize("value", [None, ""])
def test_unset_and_empty_are_false(value: str | None) -> None:
    """Unset and empty are false and never warn."""
    result = _run("env_is_true", value)
    assert "no" in result.stdout and "WARNED" not in result.stdout


def test_garbage_warns_and_defaults_false() -> None:
    """An unrecognized value warns, naming the variable, and reads as unset."""
    result = _run("env_is_true", "banana")
    assert "no" in result.stdout
    assert "WARNED" in result.stdout and "MY_FLAG" in result.stdout


@pytest.mark.parametrize("value", FALSY)
def test_env_is_false_explicit(value: str) -> None:
    """env_is_false is true only for explicit falsy forms."""
    result = _run("env_is_false", value)
    assert "yes" in result.stdout


@pytest.mark.parametrize("value", TRUTHY + [None, ""])
def test_env_is_false_not_for_truthy_or_unset(value: str | None) -> None:
    """Truthy, unset, and empty are not explicit-false.

    Default-true toggles stay on unless deliberately disabled.
    """
    result = _run("env_is_false", value)
    assert "no" in result.stdout


def test_env_is_false_garbage_warns_and_is_not_false() -> None:
    """Garbage on a default-true toggle warns and keeps the default."""
    result = _run("env_is_false", "banana")
    assert "no" in result.stdout
    assert "WARNED" in result.stdout
