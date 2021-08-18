local loaded_floaterm, _ = pcall(function() return vim.g.loaded_floaterm end)
if (not loaded_floaterm) then
 do return end
end
vim.g.floaterm_keymap_toggle = "<A-e>"
vim.g.floaterm_keymap_prev = "<A-[>"
vim.g.floaterm_keymap_next = "<A-]>"
vim.g.floaterm_keymap_new = "<A-n>"
