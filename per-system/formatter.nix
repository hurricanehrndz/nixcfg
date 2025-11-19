{ ... }:
{
  perSystem =
    {
      config,
      ...
    }:
    {
      # set nix fmt
      formatter = config.treefmt.build.wrapper;
    };
}
