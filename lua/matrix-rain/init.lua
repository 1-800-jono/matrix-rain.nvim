-- matrix-rain.nvim
-- Draws falling Matrix-style digital rain in a floating overlay.
--
-- The overlay is a non-focusable float on top of whatever's underneath, so
-- it never touches real buffer content and never steals input.

local M = {}

local defaults = {
  -- How long the effect runs before auto-closing, in ms.
  duration_ms = 2500,
  -- Safety-net duration for persist mode (closes on keypress, or this).
  persist_duration_ms = 120000,
  -- Milliseconds between animation frames.
  interval_ms = 60,
  -- How many characters trail behind the head of each drop.
  trail_len = 12,
  -- Foreground color of the rain.
  fg = '#00ff00',
}

M.config = vim.deepcopy(defaults)

--- @param opts table|nil Overrides for the default config.
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
end

--- Play the rain animation.
--- @param opts table|nil
---   persist (boolean): keep running until a keypress instead of `duration_ms`.
---   duration_ms (number): override the run duration for this call.
function M.rain(opts)
  opts = opts or {}
  local cfg = M.config
  local persist = opts.persist or false
  local duration_ms = opts.duration_ms or (persist and cfg.persist_duration_ms or cfg.duration_ms)

  local width = vim.o.columns
  local height = vim.o.lines - vim.o.cmdheight - 2
  if width < 1 or height < 1 then
    return
  end

  -- Half-width Katakana: single terminal cell wide (unlike full-width
  -- Katakana), and what the original Matrix digital-rain effect actually used.
  local chars = {}
  for i = 0xFF66, 0xFF9D do
    table.insert(chars, vim.fn.nr2char(i))
  end
  for i = 48, 57 do
    table.insert(chars, vim.fn.nr2char(i))
  end
  local function random_char()
    return chars[math.random(#chars)]
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative = 'editor',
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    focusable = false,
    zindex = 300,
  })
  if not ok then
    return
  end

  vim.api.nvim_set_hl(0, 'MatrixRain', { fg = cfg.fg, bold = true })
  vim.wo[win].winhighlight = 'Normal:MatrixRain,NormalNC:MatrixRain'

  local drops = {}
  for col = 1, width do
    drops[col] = math.random(-height, 0)
  end

  local trail_len = cfg.trail_len
  local function render()
    local grid = {}
    for row = 1, height do
      grid[row] = {}
      for col = 1, width do
        grid[row][col] = ' '
      end
    end
    for col = 1, width do
      local head = drops[col]
      for trail = 0, trail_len do
        local row = head - trail
        if row >= 1 and row <= height then
          grid[row][col] = random_char()
        end
      end
      drops[col] = drops[col] + 1
      if drops[col] - trail_len > height and math.random() > 0.95 then
        drops[col] = math.random(-height, 0)
      end
    end
    local out = {}
    for row = 1, height do
      out[row] = table.concat(grid[row])
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
    vim.bo[buf].modifiable = false
  end

  local interval = cfg.interval_ms
  local elapsed = 0
  local timer = (vim.uv or vim.loop).new_timer()
  local closed = false
  local on_key_ns
  local function close()
    if closed then
      return
    end
    closed = true
    timer:stop()
    timer:close()
    if on_key_ns then
      vim.on_key(nil, on_key_ns)
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  if persist then
    -- vim.on_key sees every keystroke without intercepting it, so the
    -- underlying window still gets the keypress normally.
    on_key_ns = vim.on_key(function()
      close()
    end)
  end

  timer:start(
    0,
    interval,
    vim.schedule_wrap(function()
      if closed or not vim.api.nvim_win_is_valid(win) then
        close()
        return
      end
      render()
      elapsed = elapsed + interval
      if elapsed >= duration_ms then
        close()
      end
    end)
  )
end

return M
