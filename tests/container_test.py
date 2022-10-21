#!/usr/bin/env pytest -vs
"""Tests for foundry container."""

# Standard Python Libraries
from datetime import datetime
import os
import time

# Third-Party Libraries
import pytest

from .utils import LogTailer, sleep_with_progress

RATE_LIMIT_MESSAGE = "429: Too Many Requests"
READY_MESSAGE = "Server started and listening on port"
RETRY_INITIAL_DELAY = 120


@pytest.mark.parametrize(
    "container",
    [pytest.lazy_fixture("main_container"), pytest.lazy_fixture("version_container")],
)
def test_container_running(container):
    """Test that the container has started."""
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
    """Wait for Foundry to be ready."""
    ATTEMPT_TIMEOUT = 180
    MAX_ATTEMPTS = 5
    log_start_time = 1
    # There is a rate limit on generating S3 URLs.  If multiple containers are
    # under test this limit can be reached.  This will cause the container to
    # exit with a non-zero exit code.  So we will retry a few times, with an
    # exponential backoff.
    for attempt in range(MAX_ATTEMPTS):
        if attempt > 0:
            sleep_with_progress(attempt, RETRY_INITIAL_DELAY)
            log_start_time = datetime.utcnow()
            main_container.restart()
        print(f"Attempt {attempt + 1} of {MAX_ATTEMPTS}")
        tailer = LogTailer(main_container, since=log_start_time)
        attempt_start_time = time.time()
        while (
            main_container.status == "running"
            and time.time() < attempt_start_time + ATTEMPT_TIMEOUT
        ):
            # Verify the container is still running
            log_line = tailer.read()
            if log_line is None:
                # No new log lines, wait a bit
                time.sleep(1)
                continue
            redacted_printer.print(log_line, end="")
            if READY_MESSAGE in log_line:
                return  # success
            if RATE_LIMIT_MESSAGE in log_line:
                print("Rate limiting detected.")
                break  # start a new attempt
            main_container.reload()
        else:
            raise Exception(
                f"Container does not seem ready.  "
                f'Expected "{READY_MESSAGE}" in the log within {ATTEMPT_TIMEOUT} seconds.'
            )
    else:
        raise Exception(
            f"Container does not seem ready.  "
            f'Expected "{READY_MESSAGE}" in the log within {MAX_ATTEMPTS} attempts.'
        )


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
        raise Exception(
            f"Container status did not transition to 'healthy' within {TIMEOUT} seconds."
        )


def test_dump_container_logs(main_container, redacted_printer):
    """Dump container logs to stdout."""
    logs = main_container.logs().decode("utf-8")
    print("Container logs:")
    redacted_printer.print(logs)


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
