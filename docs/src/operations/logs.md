# Logs And Diagnostics

Runtime logs live in `~/.local/state/hb`.

Common log files:

- `hexbox-readiness.log`
- `hexbox-idle.log`
- `init-debug.log`
- `hexbox-bridge.out.log`
- `hexbox-bridge.err.log`

Use the helper to read the most important logs:

```bash
hb builder logs readiness
hb builder logs bridge
hb builder logs bridge-out
hb builder logs boot
hb builder logs idle
hb socktainer logs
hb socktainer logs -f
```

These logs are usually the fastest way to determine whether a failure is in:

- Apple `container` runtime startup
- guest init/bootstrap
- SSH readiness
- bridge/proxy relay behavior
