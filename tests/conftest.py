"""pytest plugin configuration.

https://docs.pytest.org/en/latest/writing_plugins.html#conftest-py-plugins
"""
# Third-Party Libraries
import pytest

MAIN_SERVICE_NAME = "foundry"
VERSION_SERVICE_NAME = f"{MAIN_SERVICE_NAME}-version"

# Run pytest with PYTEST_DOCKERC_LOGPATH set to a file to capture Docker logs


@pytest.fixture(scope="session")
def main_container(dockerc, dockerc_logs):
    """Return the main container from the Docker composition."""
    # find the container by name even if it is stopped already
    return dockerc.containers(service_names=[MAIN_SERVICE_NAME], stopped=True)[0]


@pytest.fixture(scope="session")
def version_container(dockerc, dockerc_logs):
    """Return the version container from the Docker composition.

    The version container should just output the version of its underlying contents.
    """
    # find the container by name even if it is stopped already
    return dockerc.containers(service_names=[VERSION_SERVICE_NAME], stopped=True)[0]


def pytest_addoption(parser):
    """Add new commandline options to pytest."""
    parser.addoption(
        "--runslow", action="store_true", default=False, help="run slow tests"
    )


def pytest_collection_modifyitems(config, items):
    """Modify collected tests based on custom marks and commandline options."""
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)
