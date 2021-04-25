local custom_attach = function(client)
  vim.bo.omnifunc = 'v:lua.vim.lsp.omnifunc'
  local nnoremap = vim.keymap.nnoremap
  local vnoremap = vim.keymap.vnoremap

  local has_saga, _ = pcall(require, "lspsaga")
  if has_saga then
    nnoremap({"[d", function() require("lspsaga.diagnostic").lsp_jump_diagnostic_prev() end, buffer = 0})
    nnoremap({"]d", function() require("lspsaga.diagnostic").lsp_jump_diagnostic_next() end, buffer = 0})
  end

  nnoremap({"gD", vim.lsp.buf.declaration, buffer = 0})
  nnoremap({"gd", vim.lsp.buf.definition, buffer = 0})
  nnoremap({"gi", vim.lsp.buf.implementation, buffer = 0})
  nnoremap({"<space>wa", vim.lsp.buf.add_workspace_folder, buffer = 0})
  nnoremap({"<space>wr", vim.lsp.buf.remove_workspace_folder, buffer = 0})
  nnoremap({'<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, buffer = 0})
  nnoremap({"<space>D", vim.lsp.buf.type_definition, buffer = 0})
  nnoremap({"gr", vim.lsp.buf.references, buffer = 0})
  nnoremap({"<space>q", vim.lsp.diagnostic.set_loclist, buffer = 0})

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    nnoremap({",f", vim.lsp.buf.formatting, buffer = 0})
  end
  if client.resolved_capabilities.document_range_formatting then
    vnoremap({",f", vim.lsp.buf.range_formatting, buffer = 0})
  end
end

local nvim_lsp = require("lspconfig")
local capabilities = vim.lsp.protocol.make_client_capabilities()
local lsp = vim.lsp

-- Disable diagnostic virtual text
lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(
  lsp.diagnostic.on_publish_diagnostics, {
    -- Disable virtual_text
    virtual_text = false,
  }
)

-- Enable snippet support from hrsh7th/vim-vsnip
capabilities.textDocument.completion.completionItem.snippetSupport = true;
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  }
}

local servers = {"pyright", "bashls", "dockerls", "vimls", "tsserver", "rust_analyzer"}
for _, lsp_server in ipairs(servers) do
  nvim_lsp[lsp_server].setup({
    on_attach = custom_attach,
    capabilities = capabilities,
  })
end

-- lua
local lua_lsp_location = vim.fn.expand("~/.local/share/lua-lsp")
local lua_lsp = string.format("%s/.lua-language-server-unwrapped", lua_lsp_location)
local lua_lsp_build_file = string.format("%s/main.lua", lua_lsp_location)
local lua_lsp_log = string.format("--logpath=%s", vim.fn.expand("~/.cache/lua-lsp/log"))
local lua_lsp_meta = string.format("--metapath=%s", vim.fn.expand("~/.cache/lua-lsp/meta"))
require("nlua.lsp.nvim").setup(require("lspconfig"), {
  on_attach = custom_attach,
  capabilities = capabilities,
  cmd = {lua_lsp, "-E", lua_lsp_build_file, lua_lsp_log, lua_lsp_meta},
})

-- powershell
local pwsh_bundle_path = vim.fn.expand("~/.local/share/pses")
nvim_lsp.powershell_es.setup({
  on_attach = custom_attach,
  bundle_path = pwsh_bundle_path,
})
