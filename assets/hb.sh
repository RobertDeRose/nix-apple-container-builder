#!/usr/bin/env bash
set -euo pipefail

host_alias=${HB_HOST_ALIAS:?}
ssh_config=${HB_SSH_CONFIG:?}
container_bin=${HB_CONTAINER_BIN:?}
container_name=${HB_CONTAINER_NAME:?}
reconcile_host_container_internal=${HB_RECONCILE_HOST_CONTAINER_INTERNAL:?}
socktainer_enabled=${HB_SOCKTAINER_ENABLED:?}
socktainer_agent_label=${HB_SOCKTAINER_AGENT_LABEL:?}
socktainer_socket=${HB_SOCKTAINER_SOCKET:?}
socktainer_health=${HB_SOCKTAINER_HEALTH:?}
socktainer_err_log=${HB_SOCKTAINER_ERR_LOG:?}
socktainer_out_log=${HB_SOCKTAINER_OUT_LOG:?}
readiness_log=${HB_READINESS_LOG:?}
bridge_agent_label=${HB_BRIDGE_AGENT_LABEL:?}
bridge_out_log=${HB_BRIDGE_OUT_LOG:?}
bridge_err_log=${HB_BRIDGE_ERR_LOG:?}
remote_store=${HB_REMOTE_STORE:?}
start_script=${HB_START_SCRIPT:?}
stop_script=${HB_STOP_SCRIPT:?}
readiness_script=${HB_READINESS_SCRIPT:?}
expose_host_container_internal=${HB_EXPOSE_HOST_CONTAINER_INTERNAL:?}

print_mark() {
  case "$1" in
    ok) printf '[x] %s\n' "$2" ;;
    fail) printf '[ ] %s\n' "$2" ;;
    skip) printf '[-] %s\n' "$2" ;;
  esac
}

recover_container_system() {
  "$container_bin" system start --enable-kernel-install
}

status_system() {
  "$container_bin" system status --format json 2> /dev/null || return 1
}

status_container() {
  "$container_bin" inspect "$container_name" 2> /dev/null || return 1
}

status_ssh() {
  /usr/bin/ssh -F "$ssh_config" -o BatchMode=yes -o ConnectTimeout=2 "$host_alias" true > /dev/null 2>&1
}

status_remote_store() {
  nix store ping --store "$remote_store" > /dev/null 2>&1
}

status_with_retries() {
  local attempts="$1"
  shift
  local remaining="$attempts"

  while [ "$remaining" -gt 0 ]; do
    if "$@"; then
      return 0
    fi
    remaining=$((remaining - 1))
    if [ "$remaining" -gt 0 ]; then
      /bin/sleep 1
    fi
  done

  return 1
}

render_status() {
  local system_state=down
  local container_state=missing
  local ssh_state=failed
  local remote_state=failed
  local bridge_state=disabled

  if status_system > /dev/null; then
    system_state=running
  fi

  if status_container | /usr/bin/grep -q '"status"[[:space:]]*:[[:space:]]*"running"'; then
    container_state=running
  elif status_container > /dev/null 2>&1; then
    container_state=stopped
  fi

  if [ "$container_state" = running ]; then
    if status_with_retries 3 status_ssh; then
      ssh_state=ok
    else
      ssh_state=starting
    fi
  fi

  if [ "$container_state" = running ]; then
    if status_with_retries 3 status_remote_store; then
      remote_state=ok
    else
      remote_state=starting
    fi
  fi

  if launchctl print "gui/$(id -u)/$bridge_agent_label" > /dev/null 2>&1; then
    bridge_state=loaded
  fi

  printf '%-18s %s\n' COMPONENT STATE
  printf '%-18s %s\n' --------- -----
  printf '%-18s %s\n' 'container system' "$system_state"
  printf '%-18s %s\n' 'bridge agent' "$bridge_state"
  printf '%-18s %s\n' 'builder container' "$container_state"
  printf '%-18s %s\n' 'ssh handshake' "$ssh_state"
  printf '%-18s %s\n' 'remote store' "$remote_state"
}

do_repair() {
  local recovered=no
  local readiness_attempt=1
  local readiness_ok=0

  if status_system > /dev/null; then
    print_mark ok 'Apple container system running'
  else
    print_mark fail 'Apple container system unhealthy; attempting recovery'
    if recover_container_system; then
      recovered=yes
      print_mark ok 'Apple container recovery succeeded'
    else
      print_mark fail 'Apple container recovery failed'
      exit 1
    fi
  fi

  if launchctl print "gui/$(id -u)/$bridge_agent_label" > /dev/null 2>&1; then
    print_mark ok 'Bridge agent loaded'
  else
    print_mark fail 'Bridge agent not loaded'
  fi

  "$start_script" > /dev/null 2>&1 || true

  if status_container | /usr/bin/grep -q '"status"[[:space:]]*:[[:space:]]*"running"'; then
    print_mark ok 'Builder container running'
  else
    print_mark fail 'Builder container not running'
    exit 1
  fi

  while [ "$readiness_attempt" -le 3 ]; do
    if "$readiness_script" > /dev/null 2>&1; then
      readiness_ok=1
      break
    fi

    readiness_attempt=$((readiness_attempt + 1))
    if [ "$readiness_attempt" -le 3 ]; then
      "$start_script" > /dev/null 2>&1 || true
      /bin/sleep 2
    fi
  done

  if [ "$readiness_ok" -eq 1 ]; then
    print_mark ok 'SSH handshake succeeded'
  else
    print_mark fail 'SSH handshake failed'
    exit 1
  fi

  if /usr/bin/ssh -F "$ssh_config" -o BatchMode=yes "$host_alias" 'nix store ping --store https://cache.nixos.org' > /dev/null 2>&1; then
    print_mark ok 'Builder can reach cache.nixos.org'
  else
    print_mark fail 'Builder cannot reach cache.nixos.org'
    exit 1
  fi

  if nix store ping --store "$remote_store" > /dev/null 2>&1; then
    print_mark ok 'Host can reach remote store'
  else
    print_mark fail 'Host cannot reach remote store'
    exit 1
  fi

  if [ "$recovered" = yes ]; then
    print_mark ok 'Recovery was required'
  else
    print_mark skip 'Recovery not required'
  fi
}

do_logs() {
  local target="${1:-runtime}"
  shift || true
  local follow=0
  local lines=100
  local logfile

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -f | --follow) follow=1 ;;
      -n)
        shift
        lines="$1"
        ;;
      *)
        echo "unknown logs argument: $1" >&2
        exit 2
        ;;
    esac
    shift || true
  done

  case "$target" in
    idle) logfile=$HB_IDLE_LOG ;;
    readiness) logfile="$readiness_log" ;;
    bridge) logfile="$bridge_err_log" ;;
    bridge-out) logfile="$bridge_out_log" ;;
    boot)
      if [ "$follow" -eq 1 ]; then
        exec "$container_bin" logs --boot --follow "$container_name"
      else
        exec "$container_bin" logs --boot -n "$lines" "$container_name"
      fi
      ;;
    *)
      echo "unknown log target: $target" >&2
      exit 2
      ;;
  esac

  if [ ! -f "$logfile" ]; then
    echo "log file not found: $logfile" >&2
    exit 1
  fi

  if [ "$follow" -eq 1 ]; then
    exec /usr/bin/tail -n "$lines" -f "$logfile"
  else
    exec /usr/bin/tail -n "$lines" "$logfile"
  fi
}

do_gc() {
  exec /usr/bin/ssh -F "$ssh_config" "$host_alias" 'nix-collect-garbage -d'
}

do_reset() {
  "$stop_script" > /dev/null 2>&1 || true
  "$start_script"
  "$readiness_script"
  render_status
}

do_restart() {
  "$stop_script" > /dev/null 2>&1 || true
  "$start_script"
  "$readiness_script"
  render_status
}

do_ssh() {
  exec /usr/bin/ssh -F "$ssh_config" "$host_alias" "$@"
}

do_inspect() {
  printf '==> launchd bridge\n'
  launchctl print "gui/$(id -u)/$bridge_agent_label" || true
  if launchctl print "gui/$(id -u)/$socktainer_agent_label" > /dev/null 2>&1; then
    printf '\n==> launchd socktainer\n'
    launchctl print "gui/$(id -u)/$socktainer_agent_label" || true
  fi
  printf '\n==> container inspect\n'
  status_container || true
}

do_socktainer_status() {
  local agent_state=disabled
  local socket_state=missing
  local ping_state=failed

  if [ "$socktainer_enabled" != true ]; then
    echo 'socktainer is disabled' >&2
    exit 1
  fi

  if launchctl print "gui/$(id -u)/$socktainer_agent_label" > /dev/null 2>&1; then
    agent_state=loaded
  fi

  if [ -S "$socktainer_socket" ]; then
    socket_state=present
  fi

  if "$socktainer_health" > /dev/null 2>&1; then
    ping_state=ok
  fi

  printf '%-18s %s\n' COMPONENT STATE
  printf '%-18s %s\n' 'socktainer agent' "$agent_state"
  printf '%-18s %s\n' 'socktainer socket' "$socket_state"
  printf '%-18s %s\n' 'socktainer ping' "$ping_state"
  printf '%-18s %s\n' 'docker host' "unix://$socktainer_socket"
}

print_socktainer_logs() {
  local logfile="$1"
  local label="$2"

  if [ ! -f "$logfile" ]; then
    echo "log file not found: $logfile" >&2
    exit 1
  fi

  printf '==> %s\n' "$label"
  /usr/bin/tail -n 100 "$logfile"
}

do_socktainer_logs() {
  local target="${1:-both}"

  case "$target" in
    out | stdout)
      print_socktainer_logs "$socktainer_out_log" 'socktainer stdout'
      ;;
    err | stderr)
      print_socktainer_logs "$socktainer_err_log" 'socktainer stderr'
      ;;
    both)
      print_socktainer_logs "$socktainer_err_log" 'socktainer stderr'
      printf '\n'
      print_socktainer_logs "$socktainer_out_log" 'socktainer stdout'
      ;;
    *)
      echo "unknown socktainer log target: $target" >&2
      exit 2
      ;;
  esac
}

do_socktainer() {
  local subcommand="${1:-status}"

  shift || true

  case "$subcommand" in
    status)
      do_socktainer_status
      ;;
    log | logs)
      if [ "$#" -eq 0 ]; then
        do_socktainer_logs both
        exit 0
      fi

      case "$1" in
        --err | --stderr)
          do_socktainer_logs err
          ;;
        --out | --stdout)
          do_socktainer_logs out
          ;;
        err | stderr | out | stdout | both)
          do_socktainer_logs "$1"
          ;;
        *)
          echo "unknown socktainer log option: $1" >&2
          exit 2
          ;;
      esac
      ;;
    *)
      echo "unknown socktainer command: $subcommand" >&2
      exit 2
      ;;
  esac
}

do_host_check() {
  local port="${1:-}"
  local probe_cmd

  if [ -z "$port" ]; then
    echo 'usage: hb host-check <port>' >&2
    exit 2
  fi

  case "$port" in
    *[!0-9]* | '')
      echo "port must be numeric: $port" >&2
      exit 2
      ;;
  esac

  probe_cmd="nc -zvw5 host.container.internal $port"

  if [ "$expose_host_container_internal" != true ]; then
    echo 'host.container.internal exposure is disabled in services.container-builder.exposeHostContainerInternal' >&2
    exit 1
  fi

  if ! status_system > /dev/null; then
    recover_container_system > /dev/null
  fi

  if "$container_bin" run --rm docker.io/alpine:latest sh -eu -c "$probe_cmd"; then
    exit 0
  fi

  if [ "$(/usr/bin/id -u)" -eq 0 ]; then
    "$reconcile_host_container_internal"
  else
    /usr/bin/sudo "$reconcile_host_container_internal"
  fi

  exec "$container_bin" run --rm docker.io/alpine:latest sh -eu -c "$probe_cmd"
}

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ] || [ "$#" -eq 0 ]; then
  cat << 'EOF'
Usage: hb <command>

  status            Show builder status summary.
  repair            Verify builder health and attempt Apple container recovery.
  logs [target]     Show logs. Targets: idle, readiness, bridge, bridge-out, boot.
  gc                Run nix garbage collection inside the builder.
  reset             Destroy and recreate the builder container.
  restart           Restart the builder container.
  ssh               Open an SSH session to the builder.
  inspect           Show raw launchd and container inspection data.
  host-check        Verify host.container.internal reaches a host TCP port.
  socktainer        Manage Socktainer. Defaults to status; subcommands: status, log, logs.
EOF
  exit 0
fi

command="$1"
shift

case "$command" in
  status) render_status ;;
  repair) do_repair ;;
  logs) do_logs "$@" ;;
  gc) do_gc ;;
  reset) do_reset ;;
  restart) do_restart ;;
  ssh) do_ssh "$@" ;;
  inspect) do_inspect ;;
  host-check) do_host_check "$@" ;;
  socktainer) do_socktainer "$@" ;;
  *)
    echo "unknown command: $command" >&2
    exit 2
    ;;
esac
