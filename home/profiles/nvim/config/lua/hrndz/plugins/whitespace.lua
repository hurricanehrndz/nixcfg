-- vim.api.nvim_set_hl(0, "ExtraWhitespace", {bg = "#FF0000", ctermbg = "red"})
-- require("retrail").setup({
--   hlgroup = "ExtraWhitespace",
-- })

vim.g.better_whitespace_filetypes_blacklist = {
  "",
  "diff",
  "git",
  "qf",
  "gitcommit",
  "unite",
  "help",
  "markdown",
  "fugitive",
  "toggleterm",
  "alpha"
}
vim.g.strip_only_modified_lines = 1
vim.g.better_whitespace_enabled = 1
vim.cmd("autocmd BufWritePre * :StripWhitespace")
