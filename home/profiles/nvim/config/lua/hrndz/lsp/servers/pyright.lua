local M = {
  setup = function(custom_on_attach, _, capabilities)
    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            diagnosticMode = "workspace",
            inlayHints = {
              variableTypes = true,
              functionReturnTypes = true,
            },
          },
        },
      },
      on_attach = function (client, bufnr)
        custom_on_attach(client, bufnr)
      end,
      capabilities = capabilities,
    })
  end,
}

return M
