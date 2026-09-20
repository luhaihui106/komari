#!/usr/bin/env bash

set -Eeuo pipefail

if grep --recursive --line-number --extended-regexp \
  --include='*.go' \
  'MethodAgentTerminal|TerminalRequestParams|agent\.terminal\.request|web/api/terminal|XtermjsSettingsKey|[Xx]termjs' \
  internal protocol web; then
  echo "Removed terminal control surface is still referenced by Go code." >&2
  exit 1
fi

if grep --line-number --fixed-strings '/terminal' web/router/router.go; then
  echo "Removed terminal route is still registered." >&2
  exit 1
fi

echo "Removed terminal control surfaces are absent from Go code and router registration."
