{ ... }:
{
  perSystem =
    {
      config,
      ...
    }:
    {
      # define packages
      formatter = config.packages.treefmt;
    };
}
