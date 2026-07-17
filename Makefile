CONTAINER_VERSION := $(shell tr -d '[:space:]' < src/version.txt)
FOUNDRY_VERSION := $(shell echo "$(CONTAINER_VERSION)" | cut -d- -f1 | cut -d+ -f1 | cut -d. -f1-2)

# Container image repository.
IMAGE := ghcr.io/felddy/foundryvtt

# GitHub repository and the directory of branch/tag rulesets managed as code.
# Ruleset IDs are resolved at run time by name, so they are not hardcoded.
# See .github/rulesets/README.md for what the JSON contains (and a decoder
# for the GitHub App IDs it references).
REPO := felddy/foundryvtt-docker
RULESET_DIR := .github/rulesets

.PHONY: guard-version guard-gh guard-jq build test version github-output help release apply-ruleset export-ruleset

## guard-version: fail loudly if the version source is missing or empty.
guard-version:
	@test -n "$(CONTAINER_VERSION)" || { echo "ERROR: src/version.txt missing or empty" >&2; exit 1; }

## README.md: render the documentation from its template using the version.
README.md: README.md.j2 src/version.txt guard-version
	uv run --group dev python tools/render_docs.py README.md.j2 README.md $(CONTAINER_VERSION)
## build: build the container image tagged with the CONTAINER_VERSION.
build: guard-version
	docker buildx build --build-arg CONTAINER_VERSION=$(CONTAINER_VERSION) --build-arg FOUNDRY_VERSION=$(FOUNDRY_VERSION) --load --tag $(IMAGE):$(CONTAINER_VERSION) .

## test: run the test suite against the built container image.
test: guard-version
	uv run --group dev pytest tests/ --image-tag $(IMAGE):$(CONTAINER_VERSION)

## version: print the derived CONTAINER_VERSION and FOUNDRY_VERSION.
version: guard-version
	@echo "Container : $(CONTAINER_VERSION)"
	@echo "FoundryVTT: $(FOUNDRY_VERSION)"

## github-output: print key=value lines for appending to $GITHUB_OUTPUT.
github-output: guard-version
	@echo "container_version=$(CONTAINER_VERSION)"
	@echo "foundry_version=$(FOUNDRY_VERSION)"

## guard-gh: fail loudly if the GitHub CLI is unavailable.
guard-gh:
	@command -v gh >/dev/null 2>&1 || { echo "ERROR: gh (GitHub CLI) is required" >&2; exit 1; }

## guard-jq: fail loudly if jq is unavailable.
guard-jq:
	@command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 1; }

## apply-ruleset: create or update every ruleset in RULESET_DIR (IDs resolved by name).
apply-ruleset: guard-gh guard-jq
	@test -n "$$(ls $(RULESET_DIR)/*.json 2>/dev/null)" || { echo "ERROR: no ruleset files in $(RULESET_DIR)" >&2; exit 1; }
	@set -e; \
	for f in $(RULESET_DIR)/*.json; do \
	  name=$$(jq -r '.name' "$$f"); \
	  id=$$(gh api "repos/$(REPO)/rulesets" --jq "[.[] | select(.name == \"$$name\") | .id][0] // empty"); \
	  if [ -n "$$id" ]; then \
	    echo "Updating ruleset '$$name' (id $$id) in $(REPO)"; \
	    gh api --method PUT "repos/$(REPO)/rulesets/$$id" --input "$$f" >/dev/null; \
	  else \
	    echo "Creating ruleset '$$name' in $(REPO)"; \
	    gh api --method POST "repos/$(REPO)/rulesets" --input "$$f" >/dev/null; \
	  fi; \
	done; \
	echo "Done."

## export-ruleset: overwrite each file in RULESET_DIR from its live ruleset.
export-ruleset: guard-gh guard-jq
	@test -n "$$(ls $(RULESET_DIR)/*.json 2>/dev/null)" || { echo "ERROR: no ruleset files in $(RULESET_DIR)" >&2; exit 1; }
	@set -e; \
	for f in $(RULESET_DIR)/*.json; do \
	  name=$$(jq -r '.name' "$$f"); \
	  id=$$(gh api "repos/$(REPO)/rulesets" --jq "[.[] | select(.name == \"$$name\") | .id][0] // empty"); \
	  if [ -z "$$id" ]; then echo "ERROR: no ruleset named '$$name' in $(REPO)" >&2; exit 1; fi; \
	  raw=$$(gh api "repos/$(REPO)/rulesets/$$id"); \
	  printf '%s\n' "$$raw" | jq '{name, target, enforcement, conditions, bypass_actors, rules}' > "$$f.tmp"; \
	  mv "$$f.tmp" "$$f"; \
	  echo "Wrote $$f from ruleset '$$name' (id $$id)"; \
	done

## help: list the developer-invocable targets.
help:
	@echo "Available targets:"
	@echo "  apply-ruleset  Create/update the branch and tag protection rulesets (resolved by name)."
	@echo "  build          Build the container image tagged with the CONTAINER_VERSION."
	@echo "  export-ruleset Overwrite the ruleset JSON files from the live rulesets."
	@echo "  github-output  Print key=value lines for CI."
	@echo "  help           Show this help message."
	@echo "  README.md      Render README.md from README.md.j2 using the version."
	@echo "  release        Bump VERSION, re-render docs, and commit (make release VERSION=x.y.z)."
	@echo "  test           Run the test suite (uv run pytest tests/)."
	@echo "  version        Print the derived CONTAINER_VERSION and FOUNDRY_VERSION."

## release: bump the version, re-render docs, and commit the result.
release: guard-version
	@test -n "$(VERSION)" || { echo "ERROR: VERSION is required (make release VERSION=x.y.z)" >&2; exit 1; }
	./bump-version set $(VERSION)
	$(MAKE) README.md
	git add README.md
	git commit --message "Render docs for $(VERSION)"
