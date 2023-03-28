local M = {
  setup = function(on_attach, capabilities)
    local lspconfig = require("lspconfig")

    lspconfig.bashls.setup({
      filetypes = { "sh", "zsh", "bash" },
      settings = {
        bashIde = {
          globPattern = "*@(.sh|.inc|.bash|.command|.zsh|zshrc|zsh_*)",
        },
      },
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
}

return M
