#!/usr/bin/env pytest -vs
"""Tests for foundry container."""

# Standard Python Libraries
import os
import time

# Third-Party Libraries
import pytest

READY_MESSAGE = "Server started and listening on port"
RELEASE_TAG = os.getenv("RELEASE_TAG")
VERSION_FILE = "src/_version.py"


def test_container_count(dockerc):
    """Verify the test composition and container."""
    # stopped parameter allows non-running containers in results
    assert (
        len(dockerc.containers(stopped=True)) == 2
    ), "Wrong number of containers were started."


def test_environment_credentials(main_container):
    """Verify enironment is set correctly."""
    # Check for required environment varaibles.
    assert (
        "FOUNDRY_USERNAME" in os.environ
    ), "FOUNDRY_USERNAME was not in the environment"
    assert (
        "FOUNDRY_PASSWORD" in os.environ
    ), "FOUNDRY_PASSWORD was not in the environment"


@pytest.mark.slow
def test_wait_for_ready(main_container):
    """Wait for container to be ready."""
    # This could take a while, as we download the application.
    TIMEOUT = 180
    for i in range(TIMEOUT):
        logs = main_container.logs().decode("utf-8")
        if READY_MESSAGE in logs:
            break
        time.sleep(1)
    else:
        raise Exception(
            f"Container does not seem ready.  "
            f'Expected "{READY_MESSAGE}" in the log within {TIMEOUT} seconds.'
            f"\nLog output follows:\n{logs}"
        )


@pytest.mark.slow
def test_wait_for_healthy(main_container):
    """Wait for container to be healthy."""
    # This could take a while
    TIMEOUT = 180
    for i in range(TIMEOUT):
        inspect = main_container.inspect()
        status = inspect["State"]["Health"]["Status"]
        assert status != "unhealthy", "The container became unhealthy."
        if status == "healthy":
            break
        time.sleep(1)
    else:
        raise Exception(
            f"Container status did transition to 'healthy' within {TIMEOUT} seconds."
        )


def test_wait_for_exits(main_container, version_container):
    """Wait for containers to exit."""
    assert (
        version_container.wait() == 0
    ), "Container service (version) did not exit cleanly"


@pytest.mark.skipif(
    RELEASE_TAG in [None, ""], reason="this is not a release (RELEASE_TAG not set)"
)
def test_release_version():
    """Verify that release tag version agrees with the module version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        RELEASE_TAG == f"v{project_version}"
    ), "RELEASE_TAG does not match the project version"


def test_log_version(version_container):
    """Verify the container outputs the correct version to the logs."""
    version_container.wait()  # make sure container exited if running test isolated
    log_output = version_container.logs().decode("utf-8").strip()
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        log_output == project_version
    ), f"Container version output to log does not match project version file {VERSION_FILE}"


def test_container_version_label_matches(version_container):
    """Verify the container version label is the correct version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        version_container.labels["org.opencontainers.image.version"] == project_version
    ), "Dockerfile version label does not match project version"
