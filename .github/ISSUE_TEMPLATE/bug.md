---
name: 🐛 Bug report
about: Create a report to help us improve
---

# 🐛 Bug Report #

A clear and concise description of what the bug is.

## To Reproduce ##

Steps to reproduce the behavior:

- Do this
- Then this

## Expected behavior ##

A clear and concise description of what you expected to happen.

## Any helpful log output ##

Please run this command:

```bash
docker inspect --format='{{range $k, $v := .Config.Labels}}
    {{- printf "%s = \"%s\"\n" $k $v -}} {{end}}' \
    felddy/foundryvtt:latest
```

Paste the results here:

```console

```

Run the container with `CONTAINER_VERBOSE` set to `true`,and paste any useful
log output here:

```console

```
