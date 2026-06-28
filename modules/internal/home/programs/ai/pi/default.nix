{
  inputs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  # pi terminal coding agent, managed via the upstream home-manager module
  # (inputs.pi) rather than a bare package so extensions, skills, prompts,
  # themes and settings can be wired declaratively. The module installs its
  # own (wrapped) pi package, so nothing is added to home.packages here.
  #
  # The wrapper only *adds* CLI flags; pi still auto-discovers anything under
  # ~/.pi/agent. Extensions (e.g. rtk's) are contributed to the
  # programs.pi.coding-agent.extensions option from their owning modules.
  #
  # NOTE: skills/promptTemplates/themes are intentionally left unset for now.
  # They'll be wired from pi-ext selectively (work vs. personal) in a later
  # pass — we don't want to mirror everything.
  imports = [ inputs.pi.homeModules.default ];

  programs.pi.coding-agent.enable = cfg.tooling.ai.enable;
}
