return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },

    config = function()
        require('telescope').setup({})
        require('telescope').load_extension('fzf')

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.find_files, {})
        vim.keymap.set('n', '<leader>p', builtin.git_files, {})
        vim.keymap.set('n', '<leader>k', builtin.keymaps, {})
        vim.keymap.set('n', '<leader>f', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>h', builtin.help_tags, {})
    end
}
