local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
}

local config = {
  cmd = "cast",
  args = {},
  keymap = "<M-\\>",
  border = "rounded",
  width = 0.8,
  height = 0.8,
  title = " cast ",
  title_pos = "center",
  winblend = 0,
  start_insert = true,
  close_key = "<C-q>",
}

local function buf_valid()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_valid()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function compute_geometry()
  local ui = vim.api.nvim_list_uis()[1] or { width = vim.o.columns, height = vim.o.lines }
  local cols = ui.width
  local rows = ui.height
  local w = math.floor(cols * config.width)
  local h = math.floor(rows * config.height)
  local row = math.floor((rows - h) / 2)
  local col = math.floor((cols - w) / 2)
  return { relative = "editor", width = w, height = h, row = row, col = col, style = "minimal" }
end

local function open_window()
  if not buf_valid() then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile = false
  end

  local geom = compute_geometry()
  geom.border = config.border
  geom.title = config.title
  geom.title_pos = config.title_pos

  state.win = vim.api.nvim_open_win(state.buf, true, geom)
  vim.wo[state.win].winblend = config.winblend
  vim.wo[state.win].winhl = "Normal:Normal,FloatBorder:FloatBorder"

  if not state.job then
    local full_cmd = { config.cmd }
    for _, a in ipairs(config.args) do
      table.insert(full_cmd, a)
    end
    state.job = vim.fn.termopen(full_cmd, {
      on_exit = function(_, _, _)
        state.job = nil
        vim.schedule(function()
          if win_valid() then
            pcall(vim.api.nvim_win_close, state.win, true)
          end
          if buf_valid() then
            pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
          end
          state.buf, state.win = nil, nil
        end)
      end,
    })
    if state.job <= 0 then
      vim.notify("[cast] failed to start: " .. config.cmd, vim.log.levels.ERROR)
      state.job = nil
      return
    end
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = state.buf,
    once = true,
    callback = function()
      state.win = nil
    end,
  })

  vim.keymap.set("n", "q", function() M.hide() end, { buffer = state.buf, nowait = true, silent = true })

  if config.close_key and config.close_key ~= "" then
    vim.keymap.set({ "t", "n" }, config.close_key, function() M.hide() end,
      { buffer = state.buf, silent = true, desc = "Cast: hide window" })
  end

  if config.start_insert then
    vim.cmd.startinsert()
  end
end

function M.hide()
  if win_valid() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.show()
  if win_valid() then
    vim.api.nvim_set_current_win(state.win)
    if config.start_insert then vim.cmd.startinsert() end
    return
  end
  open_window()
end

function M.toggle()
  if win_valid() then
    M.hide()
  else
    M.show()
  end
end

function M.kill()
  if state.job then
    pcall(vim.fn.jobstop, state.job)
    state.job = nil
  end
  if win_valid() then
    vim.api.nvim_win_close(state.win, true)
  end
  if buf_valid() then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf, state.win = nil, nil
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)

  if vim.fn.executable(config.cmd) == 0 then
    vim.notify(("[cast] '%s' not found in PATH"):format(config.cmd), vim.log.levels.WARN)
  end

  vim.api.nvim_create_user_command("CastToggle", M.toggle, {})
  vim.api.nvim_create_user_command("CastShow", M.show, {})
  vim.api.nvim_create_user_command("CastHide", M.hide, {})
  vim.api.nvim_create_user_command("CastKill", M.kill, {})

  if config.keymap and config.keymap ~= "" then
    vim.keymap.set({ "n", "t" }, config.keymap, function() M.toggle() end,
      { desc = "Cast: toggle floating CLI", silent = true })
  end
end

return M
