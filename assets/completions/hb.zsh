# Generated from scripts/hb.sh by scripts/generate-hb-assets.sh.

_hb() {
  local -a builder_commands socktainer_commands doctor_commands

  builder_commands=('status' 'logs' 'test' 'repair' 'reset' 'gc' 'inspect' 'ssh' 'help')
  socktainer_commands=('status' 'logs' 'help')
  doctor_commands=('runtime' 'dns' 'host' 'help')

  if ((CURRENT == 2)); then
    _describe 'command' 'builder socktainer doctor help --help -h --version -V'
    return
  fi

  case "$words[2]" in
    builder)
      if ((CURRENT == 3)); then
        _describe 'builder command' builder_commands
        return
      fi

      case "$words[3]" in
        logs)
          if ((CURRENT == 4)) && [[ "$words[CURRENT]" != -* ]]; then
            _describe 'log target' 'idle readiness bridge bridge-out boot'
            return
          fi
          _describe 'option' '-f --follow -n --lines -h --help'
          ;;
        help)
          _describe 'builder command' 'status logs test repair reset gc inspect ssh'
          ;;
        ssh)
          return
          ;;
      esac
      ;;
    socktainer)
      if ((CURRENT == 3)); then
        _describe 'socktainer command' socktainer_commands
        return
      fi

      case "$words[3]" in
        logs)
          _describe 'option' '-f --follow -h --help'
          ;;
        help)
          _describe 'socktainer command' 'status logs'
          ;;
      esac
      ;;
    doctor)
      if ((CURRENT == 3)); then
        _describe 'doctor command' doctor_commands
        return
      fi

      if [[ "$words[3]" == help ]]; then
        _describe 'doctor command' 'runtime dns host'
      fi
      ;;
    help)
      _describe 'command' 'builder socktainer doctor'
      ;;
  esac
}

compdef _hb hb
