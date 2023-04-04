local null_ls = require("null-ls")
local b = null_ls.builtins
local u = require("null-ls.utils")
local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING
local DIAGNOSTICS = methods.internal.DIAGNOSTICS

local function match_conf(...)
  local patterns = ...
  local f = u.root_pattern(...)
  return function(root)
    local d = f(root)
    for _, pattern in ipairs(vim.tbl_flatten({ patterns })) do
      local c = string.format("%s/%s", d, pattern)
      if u.path.exists(c) then
        return c
      end
    end
  end
end

local yamlfixer = {
  name = "yamlfixer",
  filetypes = { "yaml" },
  method = FORMATTING,
  generator = h.formatter_factory({
    command = "yamlfixer",
    args = { "-" },
    to_stdin = true,
    -- ignore_stderr = false,
  }),
}

local swiftlint = {
  name = "swiftlint",
  filetypes = { "swift" },
  method = DIAGNOSTICS,
  generator = null_ls.generator({
    command = "swiftlint",
    args = { "--reporter", "json", "--use-stdin", "--quiet" },
    to_stdin = true,
    from_stderr = true,
    format = "json",
    on_output = h.diagnostics.from_json({
      attributes = {
        severity = "severity",
        col = "character",
        code = "rule_id",
        message = "reason",
      },
      severities = {
        ["warning"] = "Warning",
        ["error"] = "Error",
      },
    }),
    cwd = h.cache.by_bufnr(function(params)
      return u.root_pattern("Package.swift", ".git")(params.bufname)
    end),
  }),
}

local gotest = require("go.null_ls").gotest()
local gotest_codeaction = require("go.null_ls").gotest_action()
-- local golangci_lint = require("go.null_ls").golangci_lint()

local sources = {
  -- formatting
  b.formatting.alejandra,
  b.formatting.prettier.with({
    disabled_filetypes = { "typescript", "typescriptreact", "yaml" },
    extra_args = { "--prose-wrap", "always" },
  }),
  -- google style
  b.formatting.shfmt.with({
    extra_args = { "-i", "2", "-ci", "-bn", "-o" },
  }),
  b.formatting.beautysh.with({
    filetypes = { "zsh" },
    extra_args = { "--indent-size", "2" },
  }),
  b.formatting.stylua,
  b.formatting.swiftformat,
  b.formatting.puppet_lint,
  b.formatting.black.with({ extra_args = { "--fast" } }),
  b.formatting.cbfmt.with({
    extra_args = function(params)
      local c = match_conf(".cbfmt.toml")(params.root)
      if c then
        return { "--config", c }
      end
    end,
  }),

  -- diagnostics
  b.diagnostics.shellcheck.with({
    diagnostics_format = "#{m} [#{c}]",
    filetypes = { "sh", "zsh" },
    extra_args = { "-o", "require-double-brackets" },
  }),
  b.diagnostics.vale,
  b.diagnostics.markdownlint,
  b.diagnostics.flake8,
  b.diagnostics.yamllint,
  b.diagnostics.revive,

  -- custom
  yamlfixer,
  swiftlint,

  -- nivm go
  gotest,
  gotest_codeaction,
}

local M = {}
M.setup = function(custom_on_attach, formatting_callback, _)
  local has_null_ls, _ = pcall(require, "null-ls")
  if not has_null_ls then
    return
  end
  null_ls.setup({
    debug = true,
    debounce = 1000,
    default_timeout = 5000,
    sources = sources,
    on_attach = function(client, bufnr)
      formatting_callback(client, bufnr)
      custom_on_attach(client, bufnr)
    end,
  })
end

return M
