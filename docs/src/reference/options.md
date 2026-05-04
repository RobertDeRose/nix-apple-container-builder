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

See `modules/container-builder.nix` for the authoritative option defaults and
types.
