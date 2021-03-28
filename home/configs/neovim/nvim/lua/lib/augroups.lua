-- util function to define autocmd groups
local af = require("lib.autofunc")

return function(definitions)
  for group_name, definition in pairs(definitions) do
    vim.cmd("augroup " .. group_name)
    vim.cmd("autocmd!")
    for _, def in ipairs(definition) do
      af(def[1], def[2], def[3])
    end
    vim.cmd("augroup END")
  end
end
