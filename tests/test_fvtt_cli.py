#!/usr/bin/env pytest -vs
"""Tests for the bundled Foundry VTT CLI."""

# Standard Python Libraries
from pathlib import Path
import re

# Third-Party Libraries
import docker
import pytest

DOCKERFILE = Path("Dockerfile")
EXPECTED_DATA_PATH = "/data"
EXPECTED_INSTALL_PATH = "/home/node/resources/app"


@pytest.fixture(scope="session")
def fvtt_cli_version():
    """Read the pinned CLI version from the Dockerfile."""
    match = re.search(
        r"^ARG FOUNDRYVTT_CLI_VERSION=(\S+)$",
        DOCKERFILE.read_text(),
        re.MULTILINE,
    )
    assert match, "FOUNDRYVTT_CLI_VERSION not found in Dockerfile"
    return match.group(1)


def run_fvtt(image_tag, command, **kwargs):
    """Run the fvtt CLI in a fresh container and return its output."""
    client = docker.from_env()
    output = client.containers.run(
        image_tag, command, entrypoint="fvtt", remove=True, **kwargs
    )
    return output.decode("utf-8").strip()


def test_fvtt_cli_version(image_tag, fvtt_cli_version):
    """Verify the CLI runs and reports the pinned version."""
    assert run_fvtt(image_tag, ["--version"]) == fvtt_cli_version


def test_fvtt_cli_seeded_config(image_tag):
    """Verify the wrapper seeds the install and data paths on first use."""
    assert (
        run_fvtt(image_tag, ["configure", "get", "installPath"])
        == EXPECTED_INSTALL_PATH
    )
    assert run_fvtt(image_tag, ["configure", "get", "dataPath"]) == EXPECTED_DATA_PATH


def test_fvtt_cli_configuration_complete(image_tag):
    """Verify the CLI considers the seeded configuration complete."""
    assert run_fvtt(image_tag, ["configure"]) == "Configuration complete!"


def test_fvtt_cli_arbitrary_uid(image_tag):
    """Verify the CLI works when the container runs as a non-default UID."""
    assert (
        run_fvtt(image_tag, ["configure", "get", "dataPath"], user="12345:12345")
        == EXPECTED_DATA_PATH
    )
