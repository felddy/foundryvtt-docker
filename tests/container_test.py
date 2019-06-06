#!/usr/bin/env pytest -vs
"""Tests for example container."""

SECRET_PW = (
    "There are no secrets better kept than the secrets everybody guesses."  # nosec
)
ENV_VAR = "ECHO_MESSAGE"
ENV_VAR_VAL = "Hello World from docker-compose!"


def test_container(dockerc):
    """Verify the test composition and container."""
    assert len(dockerc.containers()) == 1, "Wrong number of containers were running."
    container = dockerc.containers()[0]
    assert container.is_running is True, "Expected container to be running"
    assert container.wait() == 0, "Container did not exit cleanly"
    assert (
        container.labels["com.docker.compose.service"] == "example"
    ), "Service name was different than expected"
    assert (
        container.environment[ENV_VAR] == ENV_VAR_VAL
    ), f"{ENV_VAR} value was different than expected"
    log_output = container.logs().decode("utf-8")
    assert SECRET_PW in log_output, "Secret not found in log output."
