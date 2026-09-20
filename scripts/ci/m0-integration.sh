#!/usr/bin/env bash

set -Eeuo pipefail

server_name="komari-m0-integration"
server_url="http://127.0.0.1:25774"
agent_binary="${KOMARI_AGENT_BINARY:?KOMARI_AGENT_BINARY is required}"
runtime_root="${RUNNER_TEMP:?RUNNER_TEMP is required}/komari-m0-integration"
data_dir="${runtime_root}/data"
cookie_jar="${runtime_root}/cookies.txt"
agent_log="${runtime_root}/agent.log"
server_log="${runtime_root}/server.log"
admin_username="m0-admin"
admin_password="M0-ci-password-2026"
agent_pid=""

cleanup() {
  status=$?
  if [[ -n "${agent_pid}" ]] && kill -0 "${agent_pid}" 2>/dev/null; then
    kill "${agent_pid}" 2>/dev/null || true
    wait "${agent_pid}" 2>/dev/null || true
  fi
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${server_name}"; then
    docker logs "${server_name}" >"${server_log}" 2>&1 || true
    docker rm --force "${server_name}" >/dev/null 2>&1 || true
  fi
  if [[ ${status} -ne 0 ]]; then
    echo "M0 integration failed; sanitized diagnostic tails follow."
    tail -n 120 "${server_log}" 2>/dev/null || true
    tail -n 120 "${agent_log}" 2>/dev/null \
      | sed -E 's/(token=)[^&[:space:]]+/\1[REDACTED]/g' || true
  fi
  exit "${status}"
}
trap cleanup EXIT

wait_for_http() {
  local url=$1
  local attempts=${2:-60}
  local delay=${3:-1}
  local response
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    response=$(curl --silent --show-error --fail "${url}" 2>/dev/null || true)
    if [[ -n "${response}" ]]; then
      printf '%s' "${response}"
      return 0
    fi
    sleep "${delay}"
  done
  echo "Timed out waiting for ${url}" >&2
  return 1
}

wait_for_ping() {
  local attempts=${1:-60}
  local response
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    response=$(curl --silent --show-error --fail "${server_url}/ping" 2>/dev/null || true)
    if [[ "${response}" == "pong" ]]; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for the normal application router" >&2
  return 1
}

wait_for_agent_report() {
  local node_uuid=$1
  local attempts=${2:-60}
  local response
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    response=$(curl --silent --show-error --fail \
      --cookie "${cookie_jar}" \
      --header 'Content-Type: application/json' \
      --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"common:getNodesLatestStatus\",\"params\":{\"uuid\":\"${node_uuid}\"}}" \
      "${server_url}/api/rpc2" 2>/dev/null || true)
    if jq --exit-status --arg uuid "${node_uuid}" \
      '.result.client == $uuid and .result.online == true and .result.ram_total > 0 and .result.disk_total > 0' \
      <<<"${response}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for Agent V2 report" >&2
  return 1
}

login_admin() {
  rm -f "${cookie_jar}"
  curl --silent --show-error --fail \
    --cookie-jar "${cookie_jar}" \
    --header 'Content-Type: application/json' \
    --data "{\"username\":\"${admin_username}\",\"password\":\"${admin_password}\"}" \
    "${server_url}/api/login" \
    | jq --exit-status '.status == "success"' >/dev/null
}

rm -rf "${runtime_root}"
mkdir -p "${data_dir}"

docker run --detach \
  --name "${server_name}" \
  --publish 127.0.0.1:25774:25774 \
  --volume "${data_dir}:/app/data" \
  komari-lightweight:m0 >/dev/null

install_status=$(wait_for_http "${server_url}/api/install/status")
jq --exit-status '.status == "success" and .data.required == true' \
  <<<"${install_status}" >/dev/null

curl --silent --show-error --fail \
  --header 'Content-Type: application/json' \
  --data "{\"username\":\"${admin_username}\",\"password\":\"${admin_password}\",\"sitename\":\"M0 Integration\",\"description\":\"CI only\",\"metric_dsn\":\"file:/app/data/metrics.db?mode=rwc\"}" \
  "${server_url}/api/install/complete" \
  | jq --exit-status '.status == "success"' >/dev/null

wait_for_ping 60
login_admin

removed_exec_response=$(curl --silent --show-error --fail \
  --cookie "${cookie_jar}" \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"admin:exec","params":{"command":"true","clients":["disabled"]}}' \
  "${server_url}/api/rpc2")
jq --exit-status '.error.code == -32601' <<<"${removed_exec_response}" >/dev/null

removed_exec_route_status=$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --cookie "${cookie_jar}" \
  --header 'Content-Type: application/json' \
  --data '{"command":"true","clients":["disabled"]}' \
  "${server_url}/api/admin/task/exec")
test "${removed_exec_route_status}" = "404"

for removed_method in admin:getXtermjsSettings admin:setXtermjsSettings; do
  removed_xterm_response=$(curl --silent --show-error --fail \
    --cookie "${cookie_jar}" \
    --header 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"${removed_method}\",\"params\":{}}" \
    "${server_url}/api/rpc2")
  jq --exit-status '.error.code == -32601' <<<"${removed_xterm_response}" >/dev/null
done

removed_file_rpc_response=$(curl --silent --show-error --fail \
  --cookie "${cookie_jar}" \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"admin:fileList","params":{"uuid":"disabled","path":"/"}}' \
  "${server_url}/api/rpc2")
jq --exit-status '.error.code == -32601' <<<"${removed_file_rpc_response}" >/dev/null

node_response=$(curl --silent --show-error --fail \
  --cookie "${cookie_jar}" \
  --header 'Content-Type: application/json' \
  --data '{"name":"m0-agent"}' \
  "${server_url}/api/admin/client/add")
node_uuid=$(jq --exit-status --raw-output '.uuid | select(length > 0)' <<<"${node_response}")
agent_token=$(jq --exit-status --raw-output '.token | select(length > 0)' <<<"${node_response}")

removed_file_route_status=$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --cookie "${cookie_jar}" \
  --request POST \
  "${server_url}/api/admin/client/${node_uuid}/file/upload")
test "${removed_file_route_status}" = "404"

removed_agent_file_response=$(curl --silent --show-error \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"agent.file.result","params":{"request_id":"disabled","ok":true}}' \
  "${server_url}/api/clients/v2/rpc?token=${agent_token}")
jq --exit-status '.error.code == -32601' <<<"${removed_agent_file_response}" >/dev/null

"${agent_binary}" \
  --endpoint "${server_url}" \
  --token "${agent_token}" \
  --interval 1 \
  --reconnect-interval 1 \
  --disable-auto-update \
  --disable-web-ssh >"${agent_log}" 2>&1 &
agent_pid=$!

wait_for_agent_report "${node_uuid}" 90

client_response=$(curl --silent --show-error --fail \
  --cookie "${cookie_jar}" \
  "${server_url}/api/admin/client/${node_uuid}")
jq --exit-status --arg uuid "${node_uuid}" \
  '.uuid == $uuid and .cpu_cores > 0 and (.os | length > 0) and (.version | length > 0)' \
  <<<"${client_response}" >/dev/null

docker restart "${server_name}" >/dev/null
wait_for_ping 90
login_admin
wait_for_agent_report "${node_uuid}" 90

persisted_client=$(curl --silent --show-error --fail \
  --cookie "${cookie_jar}" \
  "${server_url}/api/admin/client/${node_uuid}")
jq --exit-status --arg uuid "${node_uuid}" \
  '.uuid == $uuid and .name == "m0-agent" and .cpu_cores > 0' \
  <<<"${persisted_client}" >/dev/null

test -s "${data_dir}/komari.db"
test -s "${data_dir}/metrics.db"

echo "M0 integration passed: installation, Agent V2 report, persisted databases, container restart, and Agent reconnect."
