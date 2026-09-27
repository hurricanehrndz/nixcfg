{ ... }:
{
  # Collector only; ships SMART data to the scrutiny instance on DeepThought.
  services.scrutiny.collector = {
    enable = true;
    schedule = "daily";
    settings.host.id = "mastercontrol";
    settings.api.endpoint = "https://deepthought.hrndz.ca/storage";
  };
}
