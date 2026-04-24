if vim.g.loaded_cast == 1 then
  return
end
vim.g.loaded_cast = 1

if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("[cast] requires Neovim 0.10+", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("CastToggle", function()
  require("cast").toggle()
end, {})
