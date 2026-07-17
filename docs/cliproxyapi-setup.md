# CLIProxyAPI setup

CLIProxyAPI lets Claude Code use models from multiple OAuth providers through a
single Claude-compatible endpoint. This repository installs it as a user
service when `hrndz.tooling.ai.enable = true`.

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

## Authenticate Anthropic

To use an Anthropic model for the top-level Claude Code session, run the Claude
OAuth login once:

```sh
cli-proxy-api -config ~/.config/cli-proxy-api/config.yaml -claude-login
```

OAuth credentials for both providers are mutable runtime state under
`~/.local/share/cli-proxy-api/auth/`; Nix does not manage them.

## Configure Fable and Sol aliases

CLIProxyAPI can route the top-level session to Anthropic Fable while routing
Claude Code subagents to GPT-5.6 Sol through Codex. Add these aliases to the
`settings` attribute in
`modules/internal/home/programs/ai/cli-proxy-api/default.nix`:

```nix
oauth-model-alias = {
  claude = [
    {
      name = "claude-fable-5";
      alias = "fable";
      fork = true;
    }
  ];

  codex = [
    {
      name = "gpt-5.6-sol";
      alias = "sol";
      fork = true;
    }
  ];
};
```

Apply the configuration with `just switch`. The aliases are optional; the
upstream model IDs `claude-fable-5` and `gpt-5.6-sol` can be used directly
instead.

## Verify the proxy

```sh
curl -fsS \
  -H 'Authorization: Bearer local' \
  http://127.0.0.1:8317/v1/models | jq
```

A successful request returns the available models as JSON. After configuring
both providers and the aliases above, confirm that `fable` and `sol` are
available:

```sh
curl -fsS \
  -H 'Authorization: Bearer local' \
  http://127.0.0.1:8317/v1/models |
  jq -r '.data[].id' |
  grep -E '^(fable|sol)$'
```

An empty model list usually means the OAuth login has not completed.

## Claude aliases

The shell wrapper chooses the route from `AWS_PROFILE`:

- `AWS_PROFILE=cpe`: use `openai/gpt-5.6-sol[1m]` directly, without CLIProxyAPI.
- Any other value, or an unset profile: use `gpt-5.6-sol` through CLIProxyAPI.

```sh
unset AWS_PROFILE
claudex

AWS_PROFILE=cpe claudex
```

`claudedx` uses the same routing but adds
`--dangerously-skip-permissions`. Normal `claude` and `clauded` are unchanged.

The `fabelsol` wrapper uses both OAuth providers through CLIProxyAPI:

```sh
unset AWS_PROFILE
fabelsol
```

It starts Claude Code with `--model fable`, making Fable the top-level model,
and sets `CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol`, making Sol the default model
for subagents. The latter can equivalently use the `sol` alias above. Custom
agent definitions that explicitly select a model can override that default. The
command requires both OAuth logins and the Fable alias and is unavailable when
`AWS_PROFILE=cpe`.

`ORCHESTRATOR_MODE` and `SUB_AGENT_ID` do not select models in stock Claude
Code. The effective controls are `--model` for the top-level session and
`CLAUDE_CODE_SUBAGENT_MODEL` for default subagents.

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
