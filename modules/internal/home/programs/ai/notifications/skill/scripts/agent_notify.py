import argparse
import os
import sys
import tomllib
from pathlib import Path

import apprise


EVENTS = ("afk", "assistance", "progress")


def default_config_path():
    config_home = Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
    )
    return config_home / "agent-notifications" / "config.toml"


def load_config(path, event):
    try:
        with path.expanduser().open("rb") as config_file:
            config = tomllib.load(config_file)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ValueError(f"cannot read {path}: {error}") from error

    events = config.get("events", {})
    if not isinstance(events, dict):
        raise ValueError("[events] must be a TOML table")

    enabled = events.get(event, False)
    if not isinstance(enabled, bool):
        raise ValueError(f"events.{event} must be true or false")
    if not enabled:
        raise ValueError(f"{event} notifications are disabled in {path}")

    apprise_config = config.get("apprise", {})
    urls = (
        apprise_config.get("urls", [])
        if isinstance(apprise_config, dict)
        else []
    )
    if not urls or not isinstance(urls, list) or not all(
        isinstance(url, str) and url.strip() for url in urls
    ):
        raise ValueError(
            "apprise.urls must be a non-empty array of URL strings"
        )

    return urls


def main():
    parser = argparse.ArgumentParser(
        description="Send an opt-in agent notification through Apprise."
    )
    parser.add_argument("event", choices=EVENTS)
    parser.add_argument("message")
    parser.add_argument("--title", default="Agent notification")
    parser.add_argument("--attach", type=Path, help="screenshot or other file")
    parser.add_argument("--config", type=Path, default=default_config_path())
    parser.add_argument(
        "--dry-run", action="store_true", help="validate without sending"
    )
    args = parser.parse_args()

    try:
        urls = load_config(args.config, args.event)

        attachment = None
        if args.attach:
            if not args.attach.expanduser().is_file():
                raise ValueError(f"attachment is not a file: {args.attach}")
            attachment = args.attach.expanduser().resolve().as_uri()

        notifier = apprise.Apprise()
        if not notifier.add(urls):
            raise ValueError("one or more Apprise URLs are invalid")

        if args.dry_run:
            attachment_status = "yes" if attachment else "no"
            print(
                f"agent-notify: {args.event} dry run passed "
                f"({len(urls)} target(s), attachment={attachment_status})"
            )
            return 0

        if notifier.notify(
            body=args.message,
            title=args.title,
            attach=attachment,
        ) is not True:
            raise ValueError(
                "Apprise could not deliver to every configured target"
            )
    except ValueError as error:
        print(f"agent-notify: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
