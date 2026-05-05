#compdef hb
# Generated from scripts/hb.sh by scripts/generate-hb-assets.sh.

_hb() {
  local cmd subcmd cur
  local -a top_commands builder_commands socktainer_commands doctor_commands
  local -a builder_log_targets builder_log_options socktainer_log_options

  cur=${words[CURRENT]}
  cmd=${words[2]}
  subcmd=${words[3]}
  top_commands=('builder' 'socktainer' 'doctor' 'help')
  builder_commands=('status' 'logs' 'repair' 'reset' 'gc' 'inspect' 'ssh' 'help')
  socktainer_commands=('status' 'logs' 'help')
  doctor_commands=('runtime' 'dns' 'host' 'help')
  builder_log_targets=('idle' 'readiness' 'bridge' 'bridge-out' 'boot')
  builder_log_options=('-f' '--follow' '-n' '--lines' '<LINES>' '-h' '--help')
  socktainer_log_options=('-f' '--follow' '-h' '--help')

  case $cmd in
    '')
      _describe 'command' top_commands
      return
      ;;
    builder)
      if ((CURRENT == 2)); then
        _describe 'builder command' builder_commands
        return
      fi

      case $subcmd in
        logs)
          if [[ ${words[CURRENT - 1]:-} == -n || ${words[CURRENT - 1]:-} == --lines ]]; then
            return
          fi

          if ((CURRENT == 3)) && [[ $cur != -* ]]; then
            _describe 'log target' builder_log_targets
            return
          fi

          _describe 'option' builder_log_options
          return
          ;;
        help)
          _describe 'builder command' builder_commands
          return
          ;;
        ssh)
          return
          ;;
      esac
      ;;
    socktainer)
      if ((CURRENT == 2)); then
        _describe 'socktainer command' socktainer_commands
        return
      fi

      case $subcmd in
        logs)
          _describe 'option' socktainer_log_options
          return
          ;;
        help)
          _describe 'socktainer command' socktainer_commands
          return
          ;;
      esac
      ;;
    doctor)
      if ((CURRENT == 2)); then
        _describe 'doctor command' doctor_commands
        return
      fi

      if [[ $subcmd == help ]]; then
        _describe 'doctor command' doctor_commands
        return
      fi
      ;;
    help)
      _describe 'command' top_commands
      return
      ;;
  esac
}

_hb "$@"
