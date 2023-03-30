local M = {
  setup = function(custom_on_attach, _, capabilities)
    local lspconfig = require("lspconfig")
    lspconfig.rnix.setup({
      on_attach = function (client, bufnr)
        custom_on_attach(client, bufnr)
      end,
      capabilities = capabilities,
    })
  end,
}

return M
