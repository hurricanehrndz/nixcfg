local M = {
  setup = function(custom_on_attach, formatting_callback, capabilities)
    local lspconfig = require("lspconfig")

    lspconfig.bashls.setup({
      filetypes = { "sh", "zsh", "bash" },
      settings = {
        bashIde = {
          globPattern = "*@(.sh|.inc|.bash|.command|.zsh|zshrc|zsh_*)",
        },
      },
      on_attach = function (client, bufnr)
        formatting_callback(client, bufnr)
        custom_on_attach(client, bufnr)
      end,
      capabilities = capabilities,
    })
  end,
}

return M
