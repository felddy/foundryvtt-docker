#!/usr/bin/env python3
"""Download the foundry release using valid credentials.

EXIT STATUS
    This utility exits with one of the following values:
    0   Download completed successfully.
    >0  An error occurred.

Usage:
  download_release [--log-level=LEVEL] <username> <password> <version>
  download_release (-h | --help)

Options:
  -h --help              Show this message.
  --log-level=LEVEL      If specified, then the log level will be set to
                         the specified value.  Valid values are "debug", "info",
                         "warning", "error", and "critical". [default: info]
"""

# Standard Python Libraries
import json
import logging
from pathlib import Path
import re
import sys
from typing import Any, Dict, Optional

# Third-Party Libraries
from _version import __version__
import docopt
import requests
from requests.models import Response
from requests.sessions import Session
from schema import And, Schema, SchemaError, Use
from semver import VersionInfo
from tqdm import tqdm

CSRF_TOKEN_RE: re.Pattern = re.compile(
    r'name="csrfmiddlewaretoken"\svalue="(?P<token>.+?)"'
)
HOMEPAGE_URL: str = "https://foundryvtt.com/"
HEADERS: Dict = {
    "DNT": "1",
    "Referer": HOMEPAGE_URL,
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": "Mozilla/5.0",
}
LICENSE_PATH: Path = Path("license.json")
LICENSE_RE = re.compile(r"(?P<license>(?:[A-Z0-9]{4}-*){6})")
LOGIN_URL: str = HOMEPAGE_URL + "auth/login/"
STREAM_CHUNK_SIZE: int = 8192


def download_release(username: str, password: str, version: str) -> int:
    """Download a FoundryVTT release using the supplied credentials."""
    license_url = f"{HOMEPAGE_URL}community/{username}/licenses"
    release_url = f"{HOMEPAGE_URL}releases/download?version={version}&platform=linux"
    release_path: Path = Path(f"foundryvtt-{version}.zip")

    logging.info("Creating session.")
    session: Session = requests.session()

    # Accept the privacy policy
    session.cookies.set("privacy-policy-accepted", "accepted")

    # Make a request to the main site to get our CSRF Token
    logging.info("Requesting FoundryVTT homepage.")
    response: Response = session.get(HOMEPAGE_URL, headers=HEADERS)
    response.raise_for_status()

    # Extract csrfmiddlewaretoken
    logging.debug("Extracting input token.")
    match: Optional[re.Match[str]] = CSRF_TOKEN_RE.search(response.content.decode())
    if not match:
        logging.critical("Could not find CSRF middleware token.")
        return -1
    csrfmiddlewaretoken: str = match["token"]
    payload: Dict = {
        "csrfmiddlewaretoken": csrfmiddlewaretoken,
        "login_password": password,
        "login_redirect": "/",
        "login_username": username,
        "login": "",
    }

    logging.info(f"Logging in to Foundry website as: {username}")
    response = session.post(LOGIN_URL, headers=HEADERS, data=payload)
    response.raise_for_status()

    if "sessionid" not in session.cookies:
        logging.critical(f"Unable to log in as {username}, verify your credentials.")
        return -1
    logging.info(f"Successfully logged in as {username}.")

    logging.info("Fetching license.")
    response = session.get(license_url, headers=HEADERS)
    match = LICENSE_RE.search(response.content.decode())
    match = None
    if not match:
        logging.warning("Could not find license.")
    else:
        logging.info(f"Writing license to {LICENSE_PATH}")
        license: str = match["license"].replace("-", "")
        with LICENSE_PATH.open("w") as f:
            json.dump({"license": license}, f, indent=2)

    logging.info(f"Downloading release {version} to {release_path}")
    with session.get(release_url, headers=HEADERS, stream=True) as response:
        response.raise_for_status()
        total_size: int = int(response.headers.get("content-length", 0))
        with tqdm(total=total_size, unit="iB", unit_scale=True) as prog_bar:
            with release_path.open("wb") as f:
                for chunk in response.iter_content(chunk_size=STREAM_CHUNK_SIZE):
                    prog_bar.update(len(chunk))
                    f.write(chunk)

    logging.info("Download complete.")
    return 0


def main() -> int:
    """Process arguments and kick off download."""
    args: Dict[str, str] = docopt.docopt(__doc__, version=__version__)
    # Validate and convert arguments as needed
    schema: Schema = Schema(
        {
            "--log-level": And(
                str,
                Use(str.lower),
                lambda n: n in ("debug", "info", "warning", "error", "critical"),
                error="Possible values for --log-level are "
                + "debug, info, warning, error, and critical.",
            ),
            "<username>": str,
            "<password>": str,
            "<version>": And(
                lambda s: VersionInfo.isvalid(s),
                error="<version> must be a valid semantic version.",
            ),
            str: object,  # Don't care about other keys, if any
        }
    )

    try:
        validated_args: Dict[str, Any] = schema.validate(args)
    except SchemaError as err:
        # Exit because one or more of the arguments were invalid
        print(err, file=sys.stderr)
        return 1

    # Assign validated arguments to variables
    username: str = validated_args["<username>"]
    password: str = validated_args["<password>"]
    version: str = validated_args["<version>"]
    log_level: str = validated_args["--log-level"]

    # Set up logging
    logging.basicConfig(
        format="%(asctime)-15s %(levelname)s %(message)s", level=log_level.upper()
    )

    return download_release(username, password, version)


if __name__ == "__main__":
    sys.exit(main())
