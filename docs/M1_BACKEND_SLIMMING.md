# M1 backend slimming record

## M1a: remote command execution

Status: implemented on `develop/lightweight-v1`, pending CI acceptance.

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
