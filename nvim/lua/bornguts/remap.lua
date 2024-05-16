-- ; as :
vim.keymap.set("n", ";", ":")

-- Center in window when using vertial motion
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Suspend with Ctrl+f
vim.keymap.set("i", "<C-f>", ":sus<cr>")
vim.keymap.set("v", "<C-f>", ":sus<cr>")
vim.keymap.set("n", "<C-f>", ":sus<cr>")

-- Jump to start and end of line using the home row keys
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "L", "$")
vim.keymap.set("v", "H", "^")
vim.keymap.set("v", "L", "$")

--  Quick-save
vim.keymap.set("n", "<leader>w", ":w<CR>")

-- Open new file adjacent to current file
vim.keymap.set("n", "<leader>o", ':e <C-R>=expand("%:p:h") . "/" <CR>')

-- Paste visual selection without loosing paste content
vim.keymap.set("x", "<leader>p", "\"_dP");

-- No arrow keys --- force yourself to use the home row
vim.keymap.set("n", "<up>", "<nop>")
vim.keymap.set("n", "<down>", "<nop>")
vim.keymap.set("i", "<left>", "<nop>")
vim.keymap.set("i", "<right>", "<nop>")
vim.keymap.set("i", "<up>", "<nop>")
vim.keymap.set("i", "<down>", "<nop>")

-- Not sure what Q does, but after ThePrimagen video I don't want to know
vim.keymap.set("n", "Q", "nop");

-- Left and right can switch buffers
vim.keymap.set("n", "<left>", ":bp<CR>")
vim.keymap.set("n", "<right>", ":bn<CR>")

-- Move by line
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- <leader><leader> toggles between buffers
vim.keymap.set("n", "<leader><leader>", "<c-^>")

-- <leader>, shows/hides hidden characters
vim.keymap.set("n", "<leader>,", ":set invlist<cr>")

-- I can type :help on my own, thanks.
vim.keymap.set("n", "<F1>", "<Esc>")
vim.keymap.set("i", "<F1>", "<Esc>")

-- Move lines up and down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")


-- Call Ex to put you in directory mode
vim.keymap.set("n", "<leader>d", vim.cmd.Ex)

-- Quicklist helpers
-- vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>k", "<cmd>lprev<CR>zz")

-- Fast renaming of under the cursor word
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Make the file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
