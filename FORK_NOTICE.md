# Fork notice

This repository is an independent development fork of
[`komari-monitor/komari`](https://github.com/komari-monitor/komari).

## Fixed upstream baseline

- Upstream repository: `komari-monitor/komari`
- Upstream default branch: `main`
- Baseline commit: `0ca87aafd184ed75f9030ede0902772142af5eec`
- Baseline commit subject: `移除流量通知`
- Fork development branch: `develop/lightweight-v1`

The original `LICENSE`, `NOTICE`, copyright notices, and Git history are
retained. The upstream server is licensed under the MIT License. This fork is
not represented as an official Komari release and is not endorsed by the
upstream maintainers.

## Project scope

The fork is being reduced to a lightweight VPS monitoring, network-quality,
and multi-channel alerting platform. Remote shell execution, web terminals,
remote file management, plugins, external login providers, and unrelated
control-panel features are outside the target scope.

## Frontend transition

The upstream `komari-web` repository does not provide a clearly identified
independent license in the project baseline. Its source is therefore not copied
into this repository as this fork's public frontend product.

During M0 only, continuous integration may build a pinned upstream frontend
revision to verify server compatibility. That job does not publish the frontend,
upload a release artifact, or create a container registry image. A separately
implemented frontend based on documented APIs and protocol behavior will
replace this compatibility step before a public release.
