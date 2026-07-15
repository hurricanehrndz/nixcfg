# CLIProxyAPI setup

CLIProxyAPI lets Claude Code use GPT models through a Codex subscription. This
repository installs it as a user service when `hrndz.tooling.ai.enable = true`.

## Install and start

Enable AI tooling for the host if it is not already enabled:

```nix
hrndz.tooling.ai.enable = true;
```

Rebuild and activate the configuration:

```sh
just switch
```

This installs `cli-proxy-api`, writes its configuration, and starts the user
service on `127.0.0.1:8317`.

## Authenticate Codex

Run the OAuth login once:

```sh
cli-proxy-api -config ~/.config/cli-proxy-api/config.yaml -codex-login
```

For a headless machine, use the device flow instead:

```sh
cli-proxy-api -config ~/.config/cli-proxy-api/config.yaml -codex-device-login
```

OAuth credentials are mutable runtime state under
`~/.local/share/cli-proxy-api/auth/`; Nix does not manage them.

## Verify the proxy

```sh
curl -fsS \
  -H 'Authorization: Bearer local' \
  http://127.0.0.1:8317/v1/models | jq
```

A successful request returns the available models as JSON. An empty model list
usually means the OAuth login has not completed.

## Claude aliases

The shell wrapper chooses the route from `AWS_PROFILE`:

- `AWS_PROFILE=cpe`: use `openai/gpt-5.6-so1` directly, without CLIProxyAPI.
- Any other value, or an unset profile: use `gpt-5.6-so1` through CLIProxyAPI.

```sh
unset AWS_PROFILE
claudex

AWS_PROFILE=cpe claudex
```

`claudedx` uses the same routing but adds
`--dangerously-skip-permissions`. Normal `claude` and `clauded` are unchanged.

## Service troubleshooting

### macOS

```sh
launchctl print gui/$(id -u)/org.nix-community.home.cli-proxy-api
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.cli-proxy-api
tail -f ~/Library/Logs/cli-proxy-api.log
```

### Linux

```sh
systemctl --user status cli-proxy-api
systemctl --user restart cli-proxy-api
journalctl --user -u cli-proxy-api -f
```

If `claudex` reports a connection error, verify the service is running and
that port 8317 is listening only on localhost. If it unexpectedly bypasses the
proxy, check `echo $AWS_PROFILE`.

The generated configuration at `~/.config/cli-proxy-api/config.yaml` is a Nix
store symlink. Change
`modules/internal/home/programs/ai/cli-proxy-api/default.nix` instead of editing
the generated file.
