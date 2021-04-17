if !(vim.g.loaded_overlength) then
 do return end
end

vim.g['overlength#default_overlength'] = 120
vim.g['overlength#default_to_textwidth'] = 1
vim.g['overlength#default_grace_length'] = 1
vim.fn['overlength#disable_filetypes']({ 'markdow', 'vimwiki', 'startify', 'term', 'man', 'qf', '' })
vim.fn['overlength#set_overlength']('text', 80)
vim.fn['overlength#set_overlength']('startify', 0)
