# M0 baseline record

## 1. Baseline identity

| Item | Fixed value |
| --- | --- |
| Fork | `luhaihui106/komari` |
| Development branch | `develop/lightweight-v1` |
| Upstream | `komari-monitor/komari` |
| Upstream branch | `main` |
| Upstream commit | `0ca87aafd184ed75f9030ede0902772142af5eec` |
| Upstream compatibility version | `0.0.1` |
| Fork version line | `0.1.0` |
| Edition | `lightweight-dev` |
| Go version declared by the module | `1.25.0` |

## 2. Compatibility retained at M0

- Agent V2 HTTP/WebSocket JSON-RPC endpoints and report ingestion.
- Node token authentication, presence tracking, basic information, and metric reports.
- Scheduled Ping tasks and Ping result ingestion.
- SQLite database initialization and internal migration mechanisms.
- Password login, session handling, and TOTP.
- Existing backup, restore, logging, and diagnostics code pending M1 boundary review.

M0 does not remove database tables, routes, protocol methods, or configuration
keys. It establishes a reproducible reference point before functional removal.

## 3. Removal boundary confirmed for M1

| Capability | Main code boundary | M1 treatment |
| --- | --- | --- |
| Remote execution | `web/rpc/jsonrpc/admin.system.go`, `web/rpc/jsonrpc/admin.task.go`, `database/tasks/tasks.go`, `database/models/task.go`, Agent V2 exec methods | Remove routes, dispatch, result ingestion, models, migration registration, and tests |
| Web terminal | `web/api/terminal`, terminal routes, Agent V2 terminal method | Remove without deleting shared Agent V2 event transport |
| Remote files | `web/filemanager`, upload/preview/transfer routes, Agent V2 file methods | Remove all public/admin/agent routes and transfer state |
| Clipboard | `database/clipboard`, `database/models/clipboard.go`, `web/rpc/jsonrpc/admin.clipboard.go` | Remove model, routes, service, migration registration, and tests |
| Plugins and JavaScript runtime | `internal/plugin`, `pkg/jsruntime`, `database/models/plugin.go`, plugin routes | Remove as one dependency slice, then run `go mod tidy` |
| OAuth/OIDC | `web/oauth`, OAuth routes, `database/oauth.go`, `database/models/oauth.go`, OIDC settings | Remove while preserving password login and TOTP |
| Themes/market | theme models, theme admin routes, market download helpers | Remove after static frontend boundary is replaced |
| Complex online restore | chunk upload, archive restore/recovery web flows | Replace with CLI restore and guarded export; retain migrations |
| JavaScript notifier | `utils/messageSender/javascript` and JS runtime coupling | Remove; retain typed providers until multi-channel engine replaces them |
| Pprof | `web/api/admin/pprof.go` | Retain only behind explicit local/private diagnostic policy |
| Ping tasks | `database/tasks/ping.go`, `utils/pingSchedule.go`, Agent V2 ping methods | Retain; do not conflate with remote execution tasks |

## 4. Baseline risks

1. Existing workflows request Go `1.23` while `go.mod` declares Go `1.25.0`.
2. The server build embeds a generated frontend archive; the upstream build action follows the unpinned default frontend branch unless a ref is supplied.
3. Agent V2 Ping, terminal, file, and exec operations share transport and event-queue code; deleting the queue wholesale would break Ping.
4. The plugin system owns a JavaScript runtime with filesystem, network, and child-process capabilities and must be removed as a complete dependency slice.
5. The current repository still exposes remote-control and file-transfer routes and must not be treated as the target production product.

## 5. M0 verification gate

The `Lightweight Baseline CI` workflow must pass before M1 begins. It performs:

- full Go test suite;
- Linux amd64 server build;
- binary startup/help check;
- Docker image build;
- container startup/help check.

The compatibility frontend is pinned to commit
`3324844cfa347f18c83435f1ccf5634df7e5b768` only for this gate. The workflow
does not publish artifacts, releases, packages, or images.
