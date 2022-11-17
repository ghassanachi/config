function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end


-- ; as :
map('n', ';', ':')

-- Ctrl+c and Ctrl+j as Esc
-- Ctrl-j is a little awkward unfortunately:
-- https://github.com/neovim/neovim/issues/5916
-- So we also map Ctrl+k
map('n', '<C-j>', '<Esc>')
map('', '<C-k>', '<Esc>')
map('', '<C-c>', '<Esc>')

-- Ctrl+h to stop searching
map('v', '<C-h>', ':nohlsearch<cr>')
map('n', '<C-h>', ':nohlsearch<cr>')

-- Suspend with Ctrl+f
map('i', '<C-f>', ':sus<cr>')
map('v', '<C-f>', ':sus<cr>')
map('n', '<C-f>', ':sus<cr>')

-- Jump to start and end of line using the home row keys
map('', 'H', '^')
map('', 'L', '$')

--  Quick-save
map('n', '<leader>w', ':w<CR>')

-- Open new file adjacent to current file
map('n', '<leader>o', ':e <C-R>=expand("%:p:h") . "/" <CR>')

-- No arrow keys --- force yourself to use the home row
map('n', '<up>', '<nop>')
map('n', '<down>', '<nop>')
map('i', '<left>', '<nop>')
map('i', '<right>', '<nop>')
map('i', '<up>', '<nop>')
map('i', '<down>', '<nop>')

-- Left and right can switch buffers
map('n', '<left>', ':bp<CR>')
map('n', '<right>', ':bn<CR>')

-- Move by line
map('n', 'j', 'gj')
map('n', 'k', 'gk')

-- <leader><leader> toggles between buffers
map('n', '<leader><leader>', '<c-^>')

-- <leader>, shows/hides hidden characters
map('n', '<leader>,', ':set invlist<cr>')

-- <leader>q shows stats
map('n', '<leader>q', 'g<c-g>')

-- Keymap for replacing up to next _ or -
map('n', '<leader>m', 'ct_')

-- I can type :help on my own, thanks.
map('', '<F1>', '<Esc>')
map('i', '<F1>', '<Esc>')

-- Move lines up and down in visual mode
map('x', 'K', ":move '<-2<CR>gv-gv")
map('x', 'J', ":move '>+1<CR>gv-gv")
