local reload   = require('guts.core.utils.reload')
local Remap    = require("guts.core.keymap")
local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap
local noremap  = Remap.noremap

-- ; as :
nnoremap(';', ':')

-- Ctrl+c and Ctrl+j as Esc
-- Ctrl-j is a little awkward unfortunately:
-- https://github.com/neovim/neovim/issues/5916
-- So we also map Ctrl+k
nnoremap('<C-j>', '<Esc>')
noremap('<C-k>', '<Esc>', {})
noremap('<C-c>', '<Esc>')

-- Center in window when using vertial motion
nnoremap('<C-d>', '<C-d>zz')
nnoremap('<C-u>', '<C-u>zz')
nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')

-- Ctrl+h to stop searching
vnoremap('<C-h>', ':nohlsearch<cr>')
nnoremap('<C-h>', ':nohlsearch<cr>')

-- Suspend with Ctrl+f
inoremap('<C-f>', ':sus<cr>')
vnoremap('<C-f>', ':sus<cr>')
nnoremap('<C-f>', ':sus<cr>')

-- Jump to start and end of line using the home row keys
noremap('H', '^')
noremap('L', '$')

--  Quick-save
nnoremap('<leader>w', ':w<CR>')

-- Open new file adjacent to current file
nnoremap('<leader>o', ':e <C-R>=expand("%:p:h") . "/" <CR>')

-- No arrow keys --- force yourself to use the home row
nnoremap('<up>', '<nop>')
nnoremap('<down>', '<nop>')
inoremap('<left>', '<nop>')
inoremap('<right>', '<nop>')
inoremap('<up>', '<nop>')
inoremap('<down>', '<nop>')

-- Left and right can switch buffers
nnoremap('<left>', ':bp<CR>')
nnoremap('<right>', ':bn<CR>')

-- Move by line
nnoremap('j', 'gj')
nnoremap('k', 'gk')

-- <leader><leader> toggles between buffers
nnoremap('<leader><leader>', '<c-^>')

-- <leader>, shows/hides hidden characters
nnoremap('<leader>,', ':set invlist<cr>')

-- <leader>q shows stats
nnoremap('<leader>q', 'g<c-g>')

-- Keymap for replacing up to next _ or -
nnoremap('<leader>m', 'ct_')

-- I can type :help on my own, thanks.
noremap('<F1>', '<Esc>')
inoremap('<F1>', '<Esc>')

-- Move lines up and down in visual mode
xnoremap('K', ":move '<-2<CR>gv-gv")
xnoremap('J', ":move '>+1<CR>gv-gv")

-- Reload config
vim.api.nvim_create_user_command(
    'ReloadConfig',
    reload,
    { desc = 'Reload nvim configuration' }
)
