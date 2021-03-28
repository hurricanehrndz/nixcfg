local create_augroups = require("lib.augroups")

local autocmds = {
  open_terminal = {
    {"TermOpen",    "*",   [[setlocal norelativenumber | setlocal nonumber]]},
  },
  help_files = {
    {"Filetype", "help", [[noremap <buffer> <silent> <C-c> :q<cr>]]},
    {"Filetype", "help", [[noremap <buffer> <silent> q :q<cr>]]},
  },
  spell_files = {
    {"Filetype", "markdown", [[setl spell spl=en]]},
    {"Filetype", "gitcommit", [[setl spell spl=en]]},
    {"Filetype", "gitcommit", [[setl tw=72]]},
  },
}

-- create augroups
create_augroups(autocmds)
