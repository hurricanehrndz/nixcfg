local M = {}

M.setup = function(custom_on_attach, _, capabilities, server_name)
  local lspconfig = require("lspconfig")
  lspconfig[server_name].setup({
    on_attach = function (client, bufnr)
      custom_on_attach(client, bufnr)
    end,
    capabilities = capabilities,
  })
end

return M
