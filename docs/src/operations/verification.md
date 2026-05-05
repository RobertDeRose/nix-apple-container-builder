# Verification And Recovery

Main helper entrypoint:

```bash
hb builder
```

Recovery-aware verification path:

```bash
hb builder repair
```

Useful checks after activation:

```bash
hb builder
hb builder repair
ssh nix-builder true
nix store ping --store ssh-ng://container-builder
nix build --max-jobs 0 --rebuild nixpkgs#legacyPackages.aarch64-linux.hello
```

`hb builder repair` attempts to recover the Apple container system before
retrying the builder startup path. It also verifies:

- container system health
- bridge agent presence
- current builder container status
- SSH handshake success
- cache reachability inside the guest
- remote store reachability from the host side

Other useful helper commands:

- `hb builder reset`
- `hb builder ssh`
- `hb builder inspect`
- `hb builder gc`
- `hb doctor`
- `hb doctor runtime`
- `hb doctor dns`
- `hb doctor host`
- `hb doctor host 22`

If guest-side DNS looks wrong, first verify the defaults before setting custom
`dns.servers`. The default Apple resolver should allow both normal external
lookups and `host.container.internal` from inside the container.

If Socktainer is enabled, useful checks include:

```bash
hb socktainer
hb socktainer status
hb socktainer logs
hb socktainer logs -f
DOCKER_HOST=unix://$HOME/.socktainer/container.sock docker ps
```

If `services.container-builder.cli.completions.enable = true;` is set, `hb`
completions are installed for bash, zsh, and fish via standard Nix completion
paths. No per-shell setup files are modified by the module.
