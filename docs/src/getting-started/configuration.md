# Configuration

Minimal example:

```nix
services.container-builder = {
  enable = true;
  cpus = 4;
  memory = "8G";
  maxJobs = 4;
  bridge.enable = true;
  # Optional Docker API compatibility layer:
  # socktainer.enable = true;
};
```

Common settings to review first:

- `hostAlias`
- `port`
- `listenAddress`
- `cpus`
- `memory`
- `maxJobs`
- `bridge.enable`
- `protocol`
- `idleShutdown.enable`
- `idleShutdown.timeoutSeconds`
- `dns.*`
- `imageRepository`
- `nixVersion`
- `socktainer.enable`

The default image is the upstream pinned image:

```text
docker.io/nixos/nix:2.34.6
```

The container guest writes a minimal `nix.conf` that uses
`https://cache.nixos.org/` by default.

Current default behavior to keep in mind:

- `bridge.enable = true`
- `protocol = "ssh-ng"`
- `hostAlias = "container-builder"`
- `listenAddress = "127.0.0.1"`
- `port = 2222`
- `dns.servers = [ ]` to preserve Apple's default container resolver
- `exposeHostContainerInternal = true`
- `cli.completions.enable = false`

Avoid setting `dns.servers` unless you have verified the chosen resolvers work
correctly with Apple containers in your environment. In local testing,
overriding DNS with public resolvers broke both `host.container.internal` and
normal external lookups from inside the builder container.

If you want shell completions for `hb`, enable:

```nix
services.container-builder.cli.completions.enable = true;
```

This installs bash, zsh, and fish completion files through standard Nix
completion directories. It does not detect your current shell or modify shell
startup files.
