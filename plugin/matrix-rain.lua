if vim.g.loaded_matrix_rain then
  return
end
vim.g.loaded_matrix_rain = true

vim.api.nvim_create_user_command('MatrixRain', function(cmd_opts)
  require('matrix-rain').rain { persist = cmd_opts.bang }
end, { bang = true, desc = 'Play the matrix rain overlay (! to keep it up until a keypress)' })
