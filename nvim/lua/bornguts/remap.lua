local set = vim.keymap.set

-- ; as :
set("n", ";", ":")

-- Center in window when using vertial motion
set("n", "<C-d>", "<C-d>zz")
set("n", "<C-u>", "<C-u>zz")
set("n", "n", "nzzzv")
set("n", "N", "Nzzzv")

-- Suspend with Ctrl+f
set("i", "<C-f>", ":sus<cr>")
set("v", "<C-f>", ":sus<cr>")
set("n", "<C-f>", ":sus<cr>")

-- Jump to start and end of line using the home row keys
set("n", "H", "^")
set("n", "L", "$")
set("v", "H", "^")
set("v", "L", "$")

--  Quick-save
set("n", "<leader>w", ":w<CR>")
-- Paste visual selection without loosing paste content
set("x", "<leader>p", '"_dP')

-- No arrow keys --- force yourself to use the home row
set("n", "<up>", "<nop>")
set("n", "<down>", "<nop>")
set("i", "<left>", "<nop>")
set("i", "<right>", "<nop>")
set("i", "<up>", "<nop>")
set("i", "<down>", "<nop>")

-- Left and right can switch buffers
set("n", "<left>", ":bp<CR>")
set("n", "<right>", ":bn<CR>")

-- Move by line
set("n", "j", "gj")
set("n", "k", "gk")

-- <leader><leader> toggles between buffers
set("n", "<leader><leader>", "<c-^>")

-- <leader>, shows/hides hidden characters
set("n", "<leader>,", ":set invlist<cr>")

-- I can type :help on my own, thanks.
set("n", "<F1>", "<Esc>")
set("i", "<F1>", "<Esc>")

-- Move lines up and down in visual mode
set("v", "J", ":m '>+1<CR>gv=gv")
set("v", "K", ":m '<-2<CR>gv=gv")

-- Quicklist helpers
-- set("n", "<C-j>", "<cmd>cnext<CR>zz")
-- set("n", "<C-k>", "<cmd>cprev<CR>zz")
-- set("n", "<leader>j", "<cmd>lnext<CR>zz")
-- set("n", "<leader>k", "<cmd>lprev<CR>zz")

-- Fast renaming of under the cursor word
set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Execute the current file (useful for nvim changes)
set("n", "<leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })
