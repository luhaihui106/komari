# M1 backend slimming record

## M1a: remote command execution

Status: accepted on `develop/lightweight-v1` at commit
`fcf0dc563d403125960dc87069194975921fa1df` by GitHub Actions run
`35491811532`.

Removed as one dependency slice:

- administrator command-execution and task-result HTTP routes;
- `admin:exec` and task-query JSON-RPC methods;
- Agent V2 command dispatch and task-result ingestion methods;
- remote command task and result models, persistence helpers, cleanup work, and tests;
- automatic creation of command task tables for new installations.

Existing `tasks` and `task_results` tables are left untouched in upgraded
databases. They are no longer read, written, migrated, or exposed, which avoids
destructive startup changes before a separately versioned cleanup migration and
backup policy are defined.

Retained and regression-tested:

- Agent V2 basic information and monitoring reports;
- the shared Agent V2 event queue required by Ping;
- scheduled Ping tasks and Ping result history;
- node token creation and authenticated administration;
- SQLite data persistence and Agent reconnection across a container restart.

The CI acceptance test calls both the former REST route and `admin:exec` RPC
method and requires them to be unavailable. No shell command is sent to an
Agent during this test.

## M1b: Web Terminal

Implementation commit: `1118492e623b559e9669dc85d3e2cc1d7111d43c`.
Acceptance is determined by the latest full branch CI run containing this commit.

This slice removes the browser terminal without changing the Agent V2
monitoring or scheduled Ping contracts:

- browser and Agent terminal WebSocket routes;
- terminal session forwarding and reconnection state;
- the `agent.terminal.request` event and its protocol payload;
- xterm.js administration methods, routes, settings code, and tests;
- terminal-specific static frontend routing and README screenshots.

The generic Agent V2 event queue remains because scheduled Ping and file
transfer still use it. File transfer routes and `agent.file` are intentionally
retained for the next independently tested M1 slice.

Existing `xtermjs_settings` rows in upgraded databases are left inert. They are
not exposed or read, and can be removed later through a versioned cleanup
migration after the backup and rollback policy is established.

Acceptance requires source-level absence checks for terminal symbols and
routes, method-not-found responses for both former xterm.js RPC methods, the
full Go test suite, the pinned official Agent V2 report test, and Docker restart
and reconnect coverage.

## M1c: remote node file management

This slice removes remote filesystem access from both the panel and Agent V2:

- public preview downloads and short-lived preview tokens;
- administrator upload, download, list, search, metadata, permission, copy,
  move, create-directory, and delete operations against node files;
- Agent raw transfer streams, transfer state, and file-result ingestion;
- `agent.file` and `agent.file.result` protocol messages;
- the generic server-to-Agent event dispatcher that existed only for remote
  file operations.

The Ping-specific dispatcher and event queue remain. Database backup download
and archive restore upload routes are separately implemented and are explicitly
retained. The pinned official Agent may still advertise file capabilities, but
the server no longer exposes or accepts the associated methods.

Acceptance requires source-level absence checks for the removed RPC methods,
protocol symbols, package imports, and routes; source-level presence checks for
backup and restore routes; method-not-found responses for the former panel and
Agent methods; the full Go test suite; and the existing Agent V2 and Docker
persistence integration test.
