# Network And Access Paths

The module uses two related access paths.

## User-side SSH path

The user SSH config points at `~/.local/state/hb/proxy.sh` as a `ProxyCommand`.
That proxy:

- starts the Apple container system if needed
- starts the builder on demand
- waits for guest `sshd`
- resolves the current container IP
- relays SSH directly into the guest

This path is installed as the host-visible `nix-builder` alias, and it uses the
generated `~/.local/state/hb/known_hosts` file to verify the builder host key.
This path is used for helper access such as `ssh nix-builder true`.

## Root daemon path

The root `nix-daemon` path uses the generated root SSH config for
`${cfg.hostAlias}`. That installed host SSH config also includes the same
host-visible `nix-builder` alias so user and root-visible behavior stay aligned.
There are two transport modes.

### Bridge mode

This is the default with `bridge.enable = true`.

The bridge launch agent exposes the configured host socket:

```text
127.0.0.1:2222
```

and forwards incoming connections into the wake-and-relay path.

### Direct published-port mode

When `bridge.enable = false`, the module publishes the container SSH port
directly with `container run -p <listenAddress>:<port>:<containerPort>`.

That avoids the bridge agent entirely, but it is a different host transport
shape and should be chosen deliberately. In this mode, `listenAddress` must stay
set to `127.0.0.1` so the builder SSH transport is not exposed on non-local
interfaces.

This split exists because the direct user path and the daemon-driven path have
different compatibility constraints on macOS.
