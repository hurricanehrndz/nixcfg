{ ... }:
{
  # Collector only. hal ships its NVMe SMART data to the scrutiny instance on
  # DeepThought (hal can reach DeepThought, not the reverse), so the web UI,
  # InfluxDB, and Telegram alerting all live there. Reached via the ingress
  # FQDN since the two hosts are on different subnets.
  services.scrutiny.collector = {
    enable = true;
    schedule = "daily";
    settings.host.id = "hal";
    settings.api.endpoint = "https://deepthought.hrndz.ca/storage";
  };
}
