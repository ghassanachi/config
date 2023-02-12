local status, telescope = pcall(require, "telescope")
if (not status) then return end
local builtin = require("telescope.builtin")

-- Change style to dropdown
telescope.setup {
    pickers = {
        -- Your special builtin config goes in here
        buffers = {
            theme = "dropdown",
        },
        find_files = {
            theme = "dropdown",
            no_ignore = true
        },
        git_files = {
            theme = "dropdown",
        },
        live_grep = {
            theme = "dropdown",
        }
    },
}

-- Find files using Telescope command-line sugar.
vim.keymap.set("n", "<C-p>", builtin.find_files)
vim.keymap.set("n", "<leader>ps", builtin.find_files)
vim.keymap.set("n", "<leader>;", builtin.buffers)
vim.keymap.set("n", "<leader>g", builtin.live_grep)
vim.keymap.set("n", "<leader>h", builtin.highlights)
vim.keymap.set("n", "<leader>m", builtin.keymaps)
