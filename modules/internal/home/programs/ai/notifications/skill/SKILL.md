---
name: remote-notifications
description: Sends opt-in remote alerts through Apprise when the user asks Claude, pi, or Codex for AFK completion notifications, progress updates, operator assistance, or desktop progress screenshots. Use only after an explicit notification request.
compatibility: Requires the agent-notify command and its Agenix-managed TOML configuration.
---

# Remote Notifications

Invoke `agent-notify` only after the user explicitly requests notifications for the current task or session. The config remains authoritative: do not work around a disabled event.

## Events

- `afk`: send at the requested completion point or checkpoint.
- `assistance`: send immediately before asking for user input or approval that blocks further work. Include the exact decision or action needed.
- `progress`: send only at material milestones when the user asked for progress updates.

Use the current agent name in the title:

```bash
agent-notify afk "Implementation and checks finished." --title "pi: task complete"
agent-notify assistance "Approve the pending deployment to continue." --title "Claude needs input"
agent-notify progress "UI flow implemented; verification remains." --title "Codex: progress"
```

If the user explicitly requested desktop screenshots and a screenshot tool is available, attach the screenshot supplied by that tool:

```bash
agent-notify progress "Settings screen is ready." \
  --title "Claude: progress" --attach /absolute/path/to/screenshot.png
```

Never capture or attach screenshots without explicit permission. Avoid secrets and private windows. Delete only temporary screenshots created by the agent after successful delivery.

If `agent-notify` fails or reports that an event is disabled, tell the user in the primary interface; never claim the notification was delivered.

## Setup

The command reads its default configuration directly from the Agenix runtime secret. A credential-free schema example is installed at `~/.config/agent-notifications/config.toml.example`; do not copy credentials into the plaintext example.

Validate the deployed secret without sending:

```bash
agent-notify afk "configuration test" --dry-run
```

`--dry-run` validates the selected event, attachment, and Apprise URLs without sending. `--config /path/to/config.toml` overrides the managed secret for testing only.
