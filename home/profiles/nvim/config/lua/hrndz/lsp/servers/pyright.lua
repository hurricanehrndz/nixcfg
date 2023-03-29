local M = {
  setup = function(on_attach, capabilities)
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
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
}

return M
