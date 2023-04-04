-- Setup lspconfig.
local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")
local has_lsplines, lsp_lines = pcall(require, "lsp_lines")

if not has_cmp then
  return
end

if has_lsplines then
  lsp_lines.setup()
end

local map = require("hrndz.utils").map
map("n", "<space>lr", "<Cmd>lua vim.lsp.buf.rename()<CR>", "Rename")
map("n", "<space>la", "<Cmd>CodeActionMenu<CR>", "Code Action")
map("n", "<space>ld", "<Cmd>lua vim.diagnostic.open_float()<CR>", "Diagnostic float")
map("n", "<space>lt", "<Cmd>TroubleToggle<CR>", "Diagnostics")
map("n", "<space>lw", "<Cmd>Telescope diagnostics<CR>", "Workspace Diagnostics")
map("n", "<space>li", "<Cmd>LspInfo<CR>", "Info")
map("n", "<space>ll", [[<Cmd>lua require("lsp_lines").toggle()<CR>]], "Toggle lsp lines")

local util = require 'vim.lsp.util'
local formatting_callback = function(client, bufnr)
  vim.keymap.set('n', '<space>lf', function()
    local params = util.make_formatting_params({})
    client.request('textDocument/formatting', params, nil, bufnr)
  end, { buffer = bufnr, desc = "Format" })
end

local custom_attach = function(client, bufnr)
  local function bufmap(mode, l, r, desc)
    local opts = {}
    opts.desc = desc
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end

  bufmap("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", "Show lsp definitions")
  bufmap("n", "gD", "<Cmd>lua vim.lsp.buf.type_definition()<CR>", "Go to type definition")
  bufmap("n", "gI", "<Cmd>Telescope lsp_implementations<CR>", "Show lsp implementations")
  bufmap("n", "gr", "<Cmd>Telescope lsp_references<CR>", "Show lsp references")
  bufmap("n", "gs", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature help")
  bufmap("n", "gy", "<Cmd>lua vim.lsp.buf.document_symbol()<CR>", "Search for symbol")

  bufmap("n", "]d", "<Cmd>lua vim.diagnostic.goto_next()<CR>", "Go to next diagnostic")
  bufmap("n", "[d", "<Cmd>lua vim.diagnostic.goto_prev()<CR>", "Go to prev diagnostic")

  local codelens_enabled = (client.server_capabilities.codeLensProvider ~= false)
  if not codelens_enabled then
    vim.lsp.codelens.refresh()
  end
end

local capabilities = cmp.default_capabilities()

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.diagnostic.config({
  underline = true,
  signs = true,
  virtual_text = false,
  virtual_lines = false,
  float = {
    show_header = true,
    source = "always",
    border = "rounded",
    focusable = false,
  },
  update_in_insert = false, -- default to false
  severity_sort = true,     -- default to false
})

local lsp_servers = { "lua_ls", "rnix", "sourcekit", "bashls", "null-ls", "pyright", "go" }
for _, server_name in ipairs(lsp_servers) do
  local has_custom_setup, server = pcall(require, "hrndz.lsp.servers." .. server_name)
  if has_custom_setup then
    server.setup(custom_attach, formatting_callback, capabilities)
  else
    require("hrndz.lsp.servers.default").setup(custom_attach, formatting_callback, capabilities, server_name)
  end
end
