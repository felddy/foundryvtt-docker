#!/usr/bin/env pytest -vs
"""Tests for foundry container."""

# Standard Python Libraries
import os
import time

# Third-Party Libraries
import pytest

from .utils import LogTailer

READY_MESSAGE = "Server started and listening on port"


@pytest.mark.parametrize(
    "container",
    ["main_container", "version_container"],
)
def test_container_running(container, request):
    """Test that the container has started."""
    # Lazy fixture evaluation
    container = request.getfixturevalue(container)

    # Wait until the container is running or timeout.
    for _ in range(10):
        container.reload()
        if container.status != "created":
            break
        time.sleep(1)
    assert container.status in ("exited", "running")


@pytest.mark.xfail
def test_environment_credentials():
    """Verify environment is set correctly."""
    # Check for credential variables.
    # These are not required for pre-built images.
    assert (
        "FOUNDRY_USERNAME" in os.environ
    ), "FOUNDRY_USERNAME was not in the environment"
    assert (
        "FOUNDRY_PASSWORD" in os.environ
    ), "FOUNDRY_PASSWORD was not in the environment"


def test_wait_for_version_container_exit(version_container):
    """Wait for version container to exit cleanly."""
    assert (
        version_container.wait()["StatusCode"] == 0
    ), "The version container did not exit cleanly"


def test_log_version(version_container, project_version):
    """Verify the container outputs the correct version to the logs."""
    version_container.wait()  # make sure container exited if running test isolated
    log_output = version_container.logs().decode("utf-8").strip()
    assert (
        log_output == project_version
    ), "Container version output to log does not match project version file"


@pytest.mark.slow
def test_wait_for_ready(main_container, redacted_printer):
    """
    Wait for Foundry to be ready.

    This could take a while if we have to back off due to rate limiting.
    If the logs stop updating for too long, or the container exits, fail.
    """
    NO_LOG_TIMEOUT = 60
    tailer = LogTailer(main_container, since=1)
    timeout: float = time.time() + NO_LOG_TIMEOUT
    while (not tailer.empty()) or (
        main_container.status == "running" and time.time() < timeout
    ):
        log_line = tailer.read()
        if log_line is None:
            # No new log lines, wait a bit
            time.sleep(1)
            continue
        else:
            # The log is still alive, reset the timeout
            timeout = time.time() + NO_LOG_TIMEOUT
        redacted_printer.print(log_line, end="")
        if READY_MESSAGE in log_line:
            return  # success
        main_container.reload()
    else:
        # The container exited or we timed out
        print(
            f"Test ending... container status: {main_container.status}, log timeout: {time.time() - timeout}"
        )
        assert main_container.status == "running", "The container unexpectedly exited."
        assert (
            False
        ), "Logging stopped for {NO_LOG_TIMEOUT} seconds, and did not contain the ready message."


@pytest.mark.slow
def test_wait_for_healthy(main_container):
    """Wait for container to be healthy."""
    # It could already in an unhealthy state when we start as we may have been
    # rate limited.
    TIMEOUT = 180
    api_client = main_container.client.api
    for _ in range(TIMEOUT):
        # Verify the container is still running
        main_container.reload()
        assert main_container.status == "running", "The container unexpectedly exited."
        inspect = api_client.inspect_container(main_container.name)
        status = inspect["State"]["Health"]["Status"]
        if status == "healthy":
            break
        time.sleep(1)
    else:
        assert (
            False
        ), f"Container status did not transition to 'healthy' within {TIMEOUT} seconds."


@pytest.mark.skipif(
    os.environ.get("RELEASE_TAG") in [None, ""],
    reason="this is not a release (RELEASE_TAG not set)",
)
def test_release_version(project_version):
    """Verify that release tag version agrees with the module version."""
    assert (
        os.getenv("RELEASE_TAG") == f"v{project_version}"
    ), "RELEASE_TAG does not match the project version"


# The container version label is added during the GitHub Actions build workflow.
# It will not be present if the container is built locally.
# Skip this check if we are not running in GitHub Actions.
@pytest.mark.skipif(
    os.environ.get("GITHUB_ACTIONS") != "true", reason="not running in GitHub Actions"
)
def test_container_version_label_matches(version_container, project_version):
    """Verify the container version label is the correct version."""
    assert (
        version_container.labels["org.opencontainers.image.version"] == project_version
    ), "Container version label does not match project version"
