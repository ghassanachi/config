local status, telescope = pcall(require, "telescope")
if (not status) then return end
local builtin = require("telescope.builtin")

-- Use fzy_native for search
telescope.load_extension('fzy_native')

-- Change style to dropdown
telescope.setup {
    pickers = {
        -- Your special builtin config goes in here
        buffers = {
            sort_lastused = true,
            theme = "dropdown",
        },
        find_files = {
            sort_lastused = true,
            theme = "dropdown",
        },
        live_grep = {
            theme = "dropdown",
        }
    },
}

-- Find files using Telescope command-line sugar.
vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<leader>;', builtin.buffers, {})
vim.keymap.set('n', '<leader>s', builtin.live_grep, {})
