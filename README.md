# matrix-rain.nvim

Matrix-style digital rain for Neovim, drawn as a non-focusable floating
overlay. It never touches your real buffers and never steals input.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  '1-800-jono/matrix-rain.nvim',
  opts = {},
}
```

`opts = {}` calls `setup()` with defaults. See Configuration below to override.

## Usage

```vim
:MatrixRain   " run for a few seconds
:MatrixRain!  " keep running until the next keypress (2 min safety net)
```

Or programmatically:

```lua
require('matrix-rain').rain()
require('matrix-rain').rain { persist = true }
require('matrix-rain').rain { duration_ms = 5000 }
```

## Configuration

Defaults shown:

```lua
require('matrix-rain').setup {
  duration_ms = 2500,          -- default run duration
  persist_duration_ms = 120000, -- safety-net duration for persist mode
  interval_ms = 60,            -- ms between frames
  trail_len = 12,              -- characters trailing each drop's head
  fg = '#00ff00',              -- rain color
}
```

## Triggering it automatically

This plugin only provides the effect and the `:MatrixRain` command — it
doesn't hook itself into `VimEnter` or anything else. Wire that up yourself,
e.g.:

```lua
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    require('matrix-rain').rain()
  end,
})
```
