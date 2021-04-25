local has_telescope, telescope = pcall(require, 'telescope')

if has_telescope then
  telescope.load_extension("fzy_native")
  local nnoremap = vim.keymap.nnoremap
  -- string maps
  -- search for current word under cursor
  nnoremap({
    "<space>fw",
    function()
      return require('telescope.builtin').grep_string({ search = vim.fn.expand("<cword>") })
    end,
  })
  nnoremap({"<space>fs", require('telescope.builtin').grep_string,})
  nnoremap({"<space>fg", require('telescope.builtin').live_grep,})

  -- file finder
  nnoremap({"<C-p>", require('telescope.builtin').git_files,})
  nnoremap({"<space>ff", require('telescope.builtin').find_files,})

  -- buffer finder
  nnoremap({"<space>fb", require('telescope.builtin').buffers, })

  -- help finder
  nnoremap({"<space>fh", require('telescope.builtin').help_tags,})

  -- git maps
  nnoremap({"<space>gc", require('telescope.builtin').git_commits,})
  nnoremap({ "<space>gb", require('telescope.builtin').git_branches,})
  nnoremap({"<space>gs", require('telescope.builtin').git_status,})
  nnoremap({"<space>gp", require('telescope.builtin').git_bcommits,})
end
