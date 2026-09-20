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

if grep --recursive --line-number --extended-regexp \
  --include='*.go' \
  'MethodAgentFile|type FileOperation struct|type FileResult struct|v2\.FileResult|web/filemanager|reg\("file|func DispatchV2Event|func EnqueueV2Event|func enqueueV2Event' \
  internal protocol web; then
  echo "Removed remote file control surface is still referenced by Go code." >&2
  exit 1
fi

if grep --line-number --extended-regexp \
  '/transfer/:id|/file/upload|/file/download|/file/preview-token|/api/preview/client' \
  web/router/router.go; then
  echo "Removed remote file route is still registered." >&2
  exit 1
fi

for preserved_route in \
  'g.GET("/download/backup", admin.DownloadBackup)' \
  'uploadGroup.POST("/init", uploadHandler.Init)' \
  'uploadGroup.POST("/chunk", uploadHandler.Chunk)' \
  'uploadGroup.POST("/merge", uploadHandler.Merge)' \
  'uploadGroup.POST("/cancel", uploadHandler.Cancel)'; do
  if ! grep --quiet --fixed-strings "${preserved_route}" web/router/router.go; then
    echo "Required backup or restore route is missing: ${preserved_route}" >&2
    exit 1
  fi
done

echo "Removed terminal and remote file control surfaces are absent; backup and restore routes remain registered."
