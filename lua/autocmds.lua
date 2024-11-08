-- [[ Highlight on yank ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank { timeout = 100 }
  end,
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  pattern = '*',
})

-- [[ Disable Autocommenting on new lines ]]
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    vim.opt.formatoptions:remove { 'c', 'r', 'o' }
  end,
  group = vim.api.nvim_create_augroup('DisableAutocommenting', { clear = true }),
})

-- [[ Update file on Focus ]]
vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    vim.cmd 'checktime'
  end,
  group = vim.api.nvim_create_augroup('UpdateOnFocus', { clear = true }),
})

-- [[ Open custom file manager when it's a Directory ]]
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    if directory then
      require('tfm').open()
    end
  end,
  group = vim.api.nvim_create_augroup('custom_filemanager_ifDirectory', { clear = true }),
})

-- [[ Remove trailing whitespaces ]]
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = { '*' },
  callback = function()
    local save_cursor = vim.fn.getpos '.'
    vim.cmd [[%s/\s\+$//e]]
    vim.cmd [[%s/\n\+\%$//e]]
    vim.fn.setpos('.', save_cursor)
  end,
  group = vim.api.nvim_create_augroup('RemoveTrailingWhitespaces', { clear = true }),
})

-- [[ Restore last cursor position ]]
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    local line = vim.fn.line '\'"'
    if line > 1 and line <= vim.fn.line '$' and vim.bo.filetype ~= 'commit' and vim.fn.index({ 'xxd', 'gitrebase' }, vim.bo.filetype) == -1 then
      vim.cmd 'normal! g`"zz'
    end
  end,
})

-- [[ Reload xresources on write ]]
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  pattern = vim.fn.resolve(vim.fn.expand '~/.config/x11/xresources'),
  callback = function()
    -- cmd([[!xrdb % ; killall -USR1 st ; renew-dwm ; notify-send " - xresources reloaded"]])
    vim.cmd [[!xrdb % ; killall -USR1 st ; renew-dwm]]
  end,
  group = vim.api.nvim_create_augroup('ReloadXresources', { clear = true }),
})

-- [[ Restore cursor shape on exit]]
vim.api.nvim_create_autocmd({ 'VimLeave' }, {
  pattern = '*',
  callback = function()
    vim.cmd 'set guicursor=a:hor20-blinkon500-blinkoff500-blinkwait700'
  end,
  group = vim.api.nvim_create_augroup('RestoreCursor', { clear = true }),
})

-- [[ Recompile suckless software on write and show notification ]]
local function recompile(path)
  vim.api.nvim_create_augroup('RecompileGroup_' .. path, { clear = true })
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    pattern = vim.fn.resolve(vim.fn.expand(path)),
    callback = function()
      local dir = vim.fn.fnamemodify(path, ':h')
      local shell_cmd = string.format("cd %s && sudo make install && renew-dwm && notify-send '  refresh complete'", dir)
      vim.cmd('!' .. shell_cmd)
    end,
  })
end

recompile '~/.config/suckless/dwm/config.h'
recompile '~/.config/suckless/dmenu/config.h'
recompile '~/.config/suckless/st/config.h'
recompile '~/.config/suckless/dwmblocks/config.h'
recompile '~/.config/suckless/slock/config.h'

-- [[ Compile LaTeX using tectonic on write and open PDF with zathura ]]
-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--   pattern = "index.tex",
--   callback = function()
--     print("Running tectonic...")
--     vim.cmd('!tectonic -X build')
--     local pdf_path = 'build/default/default.pdf'
--     local check_zathura_cmd = 'lsof | grep "zathura.*' .. pdf_path .. '"'
--     local open_zathura_cmd = 'setsid -f zathura ' .. pdf_path .. ' &'
--     local check_result = vim.fn.system(check_zathura_cmd)
--     if check_result == '' then
--       vim.fn.system(open_zathura_cmd)
--     else
--       print("Zathura is already running with the PDF.")
--     end
--   end,
--   group = vim.api.nvim_create_augroup("CompileLaTeX", { clear = true }),
-- })

--[[ Close nvim if toggleterm or Outline is the last buffer ]]
-- vim.api.nvim_create_autocmd({ 'BufEnter' }, {
--   pattern = '*',
--   callback = function()
--     if vim.fn.tabpagenr '$' == 1 and vim.fn.winnr '$' == 1 and (vim.bo.ft == 'toggleterm' or vim.bo.ft == 'Outline') then
--       vim.cmd 'bd! | q'
--     end
--   end,
--   group = vim.api.nvim_create_augroup('CloseLast', { clear = true }),
-- })

-- [[ Autosave ]]
vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave', 'BufWinLeave', 'InsertLeave' }, {
  callback = function()
    if vim.bo.filetype ~= '' and vim.bo.buftype == '' then
      vim.cmd 'silent! w'
    end
  end,
  group = vim.api.nvim_create_augroup('AutoSave', { clear = true }),
})

-- [[ Write and quit typos ]]
local typos = { 'W', 'Wq', 'WQ', 'Wqa', 'WQa', 'WQA', 'WqA', 'Q', 'Qa', 'QA' }
for _, cmd in ipairs(typos) do
  vim.api.nvim_create_user_command(cmd, function(opts)
    vim.api.nvim_cmd({
      cmd = cmd:lower(),
      bang = opts.bang,
      mods = { noautocmd = true },
    }, {})
  end, { bang = true })
end
