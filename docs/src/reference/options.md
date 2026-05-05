# Options

The main option namespace is `services.container-builder`.

Important options:

- `enable`
- `hostAlias`
- `sshUser`
- `listenAddress`
- `port`
- `containerPort`
- `workingDirectory`
- `user`
- `containerBinary`
- `installer.url`
- `installer.hash`
- `installer.version`
- `containerName`
- `imageRepository`
- `nixVersion`
- `cpus`
- `memory`
- `dns.servers`
- `dns.search`
- `dns.options`
- `dns.domain`
- `dns.disable`
- `exposeHostContainerInternal`
- `systems`
- `supportedFeatures`
- `mandatoryFeatures`
- `maxJobs`
- `speedFactor`
- `protocol`
- `autoStart`
- `readiness.timeoutSeconds`
- `readiness.intervalSeconds`
- `idleShutdown.enable`
- `idleShutdown.timeoutSeconds`
- `bridge.enable`
- `cli.completions.enable`
- `socktainer.enable`
- `socktainer.binary`
- `socktainer.homeDirectory`
- `socktainer.setDockerHost`
- `socktainer.installer.url`
- `socktainer.installer.hash`
- `socktainer.installer.version`

DNS notes:

- `dns.servers` defaults to `[]`, which keeps Apple's default container
  resolver.
- `exposeHostContainerInternal` defaults to `true` and ensures
  `host.container.internal` exists through `container system dns`.
- Prefer leaving `dns.servers` empty unless you have verified custom resolvers
  work correctly with Apple containers in your environment.

Completion notes:

- `cli.completions.enable` defaults to `false`.
- When enabled, the module installs bash, zsh, and fish completion files into
  the standard Nix-managed completion directories.
- The module does not try to detect the user's shell or edit shell startup
  files.

See `modules/container-builder.nix` for the authoritative option defaults and
types.
