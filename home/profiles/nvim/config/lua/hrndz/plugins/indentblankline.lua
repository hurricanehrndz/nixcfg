-- indentlines
vim.opt.list = false
vim.opt.listchars:append "space:⋅"
vim.opt.listchars:append "eol:↴"
vim.opt.listchars:append "tab:→ "

require("indent_blankline").setup {
  show_end_of_line = true,
  space_char_blankline = " ",
  show_first_indent_level = false,
}
