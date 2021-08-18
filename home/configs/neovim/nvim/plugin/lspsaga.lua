local has_saga, saga = pcall(require, "lspsaga")

if has_saga then
  saga.init_lsp_saga()
end
