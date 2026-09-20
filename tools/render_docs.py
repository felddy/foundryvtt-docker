#!/usr/bin/env python3
"""Render Jinja2 documentation templates using version values.

The renderer operates in one of three modes:

  render-docs <template.j2> <output> <container_version>
      Render a single template to an explicit output path.  (legacy form)

  render-docs --all <container_version>
      Discover every ``*.j2`` template in the repository and render each one to
      a sibling file with the ``.j2`` suffix removed.  This keeps the README and
      every document under ``docs/`` in lock-step with the version.

  render-docs --check <container_version>
      Render every template in memory and compare it against the committed
      output on disk.  Prints a unified diff and exits non-zero if any output is
      stale or missing.  Nothing is written.

In every mode the templates receive the same version context derived from a
single semver string: ``container_version``, ``foundry_version`` (major.minor),
and ``major_version``.
"""

from __future__ import annotations

# Standard Python Libraries
import difflib
from pathlib import Path
import sys

# Third-Party Libraries
from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape
import semver

# Directory names that never contain documentation templates.  Skipping these
# keeps discovery fast and avoids rendering anything under vendored or cache
# directories.
EXCLUDED_DIRS = frozenset(
    {
        ".git",
        ".mypy_cache",
        ".pytest_cache",
        ".ruff_cache",
        ".tox",
        ".venv",
        "__pycache__",
        "node_modules",
        "venv",
    }
)

USAGE = (
    "usage:\n"
    "  render-docs <template.j2> <output> <container_version>\n"
    "  render-docs --all <container_version>\n"
    "  render-docs --check <container_version>"
)


def version_context(container_version: str) -> dict[str, str]:
    """Build the template variable context from a semver string.

    Exits with a clear error if the version is not valid semver.
    """
    try:
        version = semver.Version.parse(container_version)
    except ValueError as error:
        print(
            f"ERROR: container_version must be valid semver (x.y.z); "
            f"got {container_version!r}: {error}",
            file=sys.stderr,
        )
        sys.exit(1)
    return {
        "container_version": container_version,
        "foundry_version": f"{version.major}.{version.minor}",
        "major_version": str(version.major),
    }


def render(template_path: Path, context: dict[str, str]) -> str:
    """Render a single template file to a string."""
    env = Environment(
        autoescape=select_autoescape(),
        keep_trailing_newline=True,
        loader=FileSystemLoader(str(template_path.parent)),
        lstrip_blocks=True,
        trim_blocks=True,
        undefined=StrictUndefined,
    )
    return env.get_template(template_path.name).render(**context)


def discover_templates(root: Path) -> list[Path]:
    """Return all ``*.j2`` templates under root, skipping excluded directories."""
    templates = []
    for path in sorted(root.rglob("*.j2")):
        if EXCLUDED_DIRS.intersection(path.parts):
            continue
        templates.append(path)
    return templates


def output_path(template_path: Path) -> Path:
    """Map a template path to its rendered output path (drop the .j2 suffix)."""
    return template_path.with_suffix("")


def render_single(template_path: Path, output: str, container_version: str) -> None:
    """Render one template to an explicit output path (legacy behavior)."""
    context = version_context(container_version)
    rendered = render(template_path, context)
    Path(output).write_text(rendered, encoding="utf-8", newline="\n")


def render_all(container_version: str) -> None:
    """Render every discovered template to its sibling output file."""
    context = version_context(container_version)
    templates = discover_templates(Path("."))
    if not templates:
        print("WARNING: no '*.j2' templates found.", file=sys.stderr)
        return
    for template_path in templates:
        rendered = render(template_path, context)
        out = output_path(template_path)
        out.write_text(rendered, encoding="utf-8", newline="\n")
        print(f"rendered {template_path} -> {out}")


def check_all(container_version: str) -> None:
    """Verify every rendered output is in sync with its template.

    Prints a unified diff for each stale or missing output and exits non-zero
    when any are found.  Writes nothing.
    """
    context = version_context(container_version)
    templates = discover_templates(Path("."))
    stale: list[Path] = []
    for template_path in templates:
        out = output_path(template_path)
        rendered = render(template_path, context)
        committed = out.read_text(encoding="utf-8") if out.exists() else None
        if committed == rendered:
            continue
        stale.append(out)
        committed_lines = (committed or "").splitlines(keepends=True)
        print(f"ERROR: {out} is out of sync with {template_path}.", file=sys.stderr)
        diff = difflib.unified_diff(
            committed_lines,
            rendered.splitlines(keepends=True),
            fromfile=f"{out} (committed)",
            tofile=f"{out} (rendered)",
        )
        sys.stderr.writelines(diff)
        print("", file=sys.stderr)
    if stale:
        print(
            "Regenerate with 'make docs' and commit the result.",
            file=sys.stderr,
        )
        sys.exit(1)


def main() -> None:
    """Dispatch to the requested render mode based on command-line arguments."""
    args = sys.argv[1:]
    if len(args) == 2 and args[0] in ("--all", "--check"):
        mode, container_version = args
        if mode == "--all":
            render_all(container_version)
        else:
            check_all(container_version)
    elif len(args) == 3 and not args[0].startswith("-"):
        template, output, container_version = args
        render_single(Path(template), output, container_version)
    else:
        print(USAGE, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
