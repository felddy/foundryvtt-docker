#!/usr/bin/env python3
"""Download the foundry release using valid credentials."""

# Standard Python Libraries
import argparse
import logging
from pathlib import Path
import re
from re import Match
import sys
from typing import Optional

# Third-Party Libraries
import requests
from requests.sessions import Session

CSRF_TOKEN_RE = re.compile(r'name="csrfmiddlewaretoken"\svalue="(?P<token>.+?)"')
HOMEPAGE_URL = "https://foundryvtt.com/"
HEADERS = {
    "DNT": "1",
    "Referer": HOMEPAGE_URL,
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": "Mozilla/5.0",
}
LOGIN_URL = HOMEPAGE_URL + "auth/login/"


def download_release(username: str, password: str, version: str) -> int:
    """Download a FoundryVTT release using the supplied credentials."""
    release_url = f"{HOMEPAGE_URL}releases/download?version={version}&platform=linux"
    release_path = Path(f"foundryvtt-{version}.zip")

    logging.info("Creating session.")
    session: Session = requests.session()

    # Accept the privacy policy
    session.cookies.set("privacy-policy-accepted", "accepted")

    # Make a request to the main site to get our CSRF Token
    logging.info("Requesting FoundryVTT homepage.")
    response = session.get(HOMEPAGE_URL, headers=HEADERS)
    response.raise_for_status()

    # Extract csrfmiddlewaretoken
    logging.debug("Extracting input token.")
    match: Optional[Match[str]] = CSRF_TOKEN_RE.search(response.content.decode())
    if not match:
        logging.fatal("Could not find CSRF middleware token.")
        return -1
    csrfmiddlewaretoken: str = match["token"]
    import IPython

    IPython.embed()
    sys.exit(0)
    payload = {
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
        logging.fatal(f"Unable to log in as {username}, verify your credentials.")
        return -1

    logging.info(f"Downloading release {version} to {release_path}")
    with session.get(release_url, headers=HEADERS, stream=True) as response:
        response.raise_for_status()
        with release_path.open("wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
    logging.info("Download complete.")
    return 0


def main() -> int:
    """Process arguments and kick off download."""
    # Set up logging
    logging.basicConfig(format="%(asctime)-15s %(levelname)s %(message)s", level="INFO")
    parser = argparse.ArgumentParser(description="Download Foundry VTT release.")
    parser.add_argument("username", type=str, help="Foundry username.")
    parser.add_argument("password", type=str, help="Foundry password.")
    parser.add_argument("version", type=str, help="Release version.")
    args = parser.parse_args()
    return download_release(args.username, args.password, args.version)


if __name__ == "__main__":
    sys.exit(main())
