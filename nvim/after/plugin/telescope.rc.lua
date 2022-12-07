local status, telescope = pcall(require, "telescope")
if (not status) then return end
local nnoremap = require("guts.core.keymap").nnoremap
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
        },
        live_grep = {
            theme = "dropdown",
        }
    },
}
-- Use fzy_native for search
telescope.load_extension('fzf')

-- Find files using Telescope command-line sugar.
nnoremap('<C-p>', builtin.find_files)
nnoremap('<leader>;', builtin.buffers)
nnoremap('<leader>s', builtin.live_grep)
nnoremap('<leader>h', builtin.highlights)
