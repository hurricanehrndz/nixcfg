{ ... }:
{
  # Collector only. Lucy ships its SMART data to the scrutiny instance on
  # DeepThought, where the web UI, InfluxDB, and Telegram alerting all live.
  # Reached via the ingress FQDN so it works regardless of subnet.
  services.scrutiny.collector = {
    enable = true;
    schedule = "daily";
    settings.host.id = "Lucy";
    settings.api.endpoint = "https://deepthought.hrndz.ca/storage";
  };
}
