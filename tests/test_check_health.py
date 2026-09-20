"""Unit tests for src/check_health.sh.

The script is executed with a stub `curl` on PATH that records its
arguments, and DATA_DIR pointed at a temporary directory so each test
controls the options.json the script reads.
"""

# Standard Python Libraries
import json
from pathlib import Path
import stat
import subprocess

CHECK_HEALTH = Path(__file__).parent.parent / "src" / "check_health.sh"

CURL_STUB = """\
#!/bin/bash
printf '%s\\n' "$@" > "${CURL_ARGS_FILE}"
exit 0
"""


def _run(
    tmp_path: Path,
    env: dict | None = None,
    options: dict | None = None,
) -> list[str]:
    """Run check_health.sh and return the arguments the curl stub received."""
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(exist_ok=True)
    curl = bin_dir / "curl"
    curl.write_text(CURL_STUB)
    curl.chmod(curl.stat().st_mode | stat.S_IEXEC)

    data_dir = tmp_path / "data"
    (data_dir / "Config").mkdir(parents=True, exist_ok=True)
    if options is not None:
        (data_dir / "Config" / "options.json").write_text(json.dumps(options))

    args_file = tmp_path / "curl-args.txt"
    merged_env = {
        "PATH": f"{bin_dir}:/usr/bin:/bin",
        "DATA_DIR": str(data_dir),
        "CURL_ARGS_FILE": str(args_file),
        **(env or {}),
    }
    result = subprocess.run(
        ["bash", str(CHECK_HEALTH)],
        capture_output=True,
        text=True,
        env=merged_env,
        timeout=10,
    )
    assert result.returncode == 0, result.stderr
    return args_file.read_text().splitlines()


def _url(args: list[str]) -> str:
    return args[-1]


def test_defaults(tmp_path: Path) -> None:
    """No config file and no env vars probe http on the default port."""
    args = _run(tmp_path)
    assert _url(args) == "http://localhost:30000/api/status"


def test_env_ssl_selects_https(tmp_path: Path) -> None:
    """FOUNDRY_SSL_CERT/KEY in the environment select https."""
    args = _run(
        tmp_path,
        env={"FOUNDRY_SSL_CERT": "cert.pem", "FOUNDRY_SSL_KEY": "key.pem"},
    )
    assert _url(args) == "https://localhost:30000/api/status"


def test_options_json_ssl_selects_https(tmp_path: Path) -> None:
    """SSL configured only in options.json (e.g. via the setup UI) selects https.

    This is the failure mode of felddy/foundryvtt-docker#1398: the previous
    check consulted only the environment and probed http forever.
    """
    args = _run(
        tmp_path,
        options={"sslCert": "cert.pem", "sslKey": "key.pem"},
    )
    assert _url(args) == "https://localhost:30000/api/status"


def test_route_prefix_from_options(tmp_path: Path) -> None:
    """A routePrefix in options.json is included in the probe path."""
    args = _run(tmp_path, options={"routePrefix": "game"})
    assert _url(args) == "http://localhost:30000/game/api/status"


def test_route_prefix_from_env(tmp_path: Path) -> None:
    """FOUNDRY_ROUTE_PREFIX still works as a fallback."""
    args = _run(tmp_path, env={"FOUNDRY_ROUTE_PREFIX": "game"})
    assert _url(args) == "http://localhost:30000/game/api/status"


def test_custom_port_from_options(tmp_path: Path) -> None:
    """A preserved options.json with a custom port is probed on that port."""
    args = _run(tmp_path, options={"port": 12345})
    assert _url(args) == "http://localhost:12345/api/status"


def test_unix_socket_probe(tmp_path: Path) -> None:
    """A unix-socket server is probed through the socket, not a TCP port."""
    args = _run(tmp_path, options={"unixSocket": "/data/foundry.sock"})
    assert "--unix-socket" in args
    assert args[args.index("--unix-socket") + 1] == "/data/foundry.sock"
    assert _url(args) == "http://localhost/api/status"


def test_null_values_in_options_are_ignored(tmp_path: Path) -> None:
    """Explicit nulls in options.json fall through to env/defaults."""
    args = _run(
        tmp_path,
        options={"sslCert": None, "sslKey": None, "routePrefix": None},
    )
    assert _url(args) == "http://localhost:30000/api/status"
