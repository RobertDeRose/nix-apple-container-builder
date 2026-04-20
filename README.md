# nix-apple-container-builder

<p align="center">
  <img src="assets/logo.png" alt="nix-apple-container-builder logo" width="240" />
</p>

`nix-apple-container-builder` is a `nix-darwin` module that configures an
Apple Container based `aarch64-linux` remote builder for Nix.

Current design highlights:

- installs Apple `container` from the official signed GitHub release package
- configures `nix.buildMachines` for `ssh-ng://container-builder`
- manages a durable state directory under `~/.local/state/container-builder`
- installs launch agents for the container runtime and the SSH bridge
- configures container DNS explicitly for cache resolution
- waits for a real SSH handshake before considering the builder ready
- currently uses a `socat` bridge into `container exec`

## Module

The flake exports:

- `darwinModules.default`
- `darwinModules.container-builder`

## Example

```nix
{
  inputs.apple-container-builder.url = "github:RobertDeRose/nix-apple-container-builder";

  outputs = inputs: {
    darwinConfigurations.my-host = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        inputs.apple-container-builder.darwinModules.default
        {
          services.container-builder = {
            enable = true;
            cpus = 4;
            maxJobs = 4;
            # Optional override if you do not want to use config.system.primaryUser.
            user = "myuser";
          };
        }
      ];
    };
  };
}
```

## Status

This module is functional but still in progress.

Known open areas:

- live runtime verification on a real machine
- possible direct port publishing instead of `socat`
- on-demand lifecycle

## DNS

The module now exposes container DNS settings directly and defaults to public
recursive resolvers so the builder can resolve `cache.nixos.org`.

The builder container name is automatically versioned from a derivation-backed
configuration spec. When relevant module settings change, the derivation store
path changes too, and the module removes older `nix-builder-*` containers and
recreates the builder with the current configuration during startup.

Available options:

- `services.container-builder.dns.servers`
- `services.container-builder.dns.search`
- `services.container-builder.dns.options`
- `services.container-builder.dns.domain`
- `services.container-builder.dns.disable`

The builder container also writes a minimal `nix.conf` with
`https://cache.nixos.org/` configured as a substituter.

Example:

```nix
services.container-builder = {
  enable = true;
  dns.servers = [ "1.1.1.1" "8.8.8.8" ];
};
```

Suggested validation after activation:

```bash
~/.local/state/container-builder/verify-builder.sh
```

The generated helper checks:

- `container system status`
- SSH connectivity to `container-builder`
- Nix cache reachability inside the builder
- `ssh-ng://container-builder` reachability from the host daemon side

If the Apple container system is hung, the helper now attempts recovery by:

1. unloading `~/Library/LaunchAgents/org.nixos.container-builder-runtime.plist`
2. running `container system start --enable-kernel-install`

See `apple-container_spec.md` and `docs/poc/README.md` for the detailed design
notes and migration history.
