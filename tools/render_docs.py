#!/usr/bin/env python3
"""Render a Jinja2 template to an output file using version values."""

# Standard Python Libraries
from pathlib import Path
import sys

# Third-Party Libraries
from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape
import semver


def main() -> None:
    """Render a template to an output file from command-line arguments."""
    if len(sys.argv) != 4:
        print(
            "usage: render_docs.py <template.j2> <output> <container_version>",
            file=sys.stderr,
        )
        sys.exit(1)

    template_path, output, container_version = (
        Path(sys.argv[1]),
        sys.argv[2],
        sys.argv[3],
    )
    env = Environment(
        autoescape=select_autoescape(),
        keep_trailing_newline=True,
        loader=FileSystemLoader(str(template_path.parent)),
        lstrip_blocks=True,
        trim_blocks=True,
        undefined=StrictUndefined,
    )
    try:
        version = semver.Version.parse(container_version)
    except ValueError as error:
        print(
            f"ERROR: container_version must be valid semver (x.y.z); "
            f"got {container_version!r}: {error}",
            file=sys.stderr,
        )
        sys.exit(1)

    rendered = env.get_template(template_path.name).render(
        container_version=container_version,
        foundry_version=f"{version.major}.{version.minor}",
        major_version=str(version.major),
    )
    Path(output).write_text(rendered, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
