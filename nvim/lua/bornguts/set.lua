-- use system clipboard
vim.opt.clipboard:prepend { 'unnamed', 'unnamedplus' }
vim.opt.clipboard:append { 'unnamedplus' }

vim.opt.nu = true
vim.opt.relativenumber = true

-- Prefer fish for `:!` and `:terminal`, but fall back to the login shell when
-- it is absent -- dev boxes do not have fish, and an unresolvable 'shell'
-- breaks every shell-out (including plugins that use jobstart).
if vim.fn.executable('fish') == 1 then
    vim.opt.shell = 'fish'
else
    vim.opt.shell = vim.env.SHELL or '/bin/bash'
end

vim.opt.errorbells = false
vim.opt.showcmd = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search

vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.colorcolumn = '80'
vim.opt.background = 'dark'

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50

-- Don't pass messages to |ins-completion-menu|.
vim.opt.shortmess:append("c")

-- Remap leader key
vim.g.mapleader = " "
