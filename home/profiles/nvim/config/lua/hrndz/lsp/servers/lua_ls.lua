local M = {}

M.setup = function(on_attach, capabilities)
  local lspconfig = require("lspconfig")
  local has_neodev, neodev = pcall(require, "neodev")
  if not has_neodev then
    return
  end
  neodev.setup({
    override = function(root_dir, library)
      if require("neodev.util").has_file(root_dir, "users/profiles/nvim/default.nix") then
        library.enabled = true
        library.plugins = true
      end
    end,
  })
  lspconfig.lua_ls.setup({
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        completion = {
          callSnippet = "Replace",
        },
      },
    },
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

return M
