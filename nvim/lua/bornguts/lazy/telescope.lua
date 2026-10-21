return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- The only part of telescope needing a C toolchain (build = 'make'),
        -- so on a dev box we keep telescope and drop just the native sorter.
        -- See lua/bornguts/devbox.lua.
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
            enabled = require("bornguts.devbox").full,
        },
    },

    config = function()
        require('telescope').setup({})
        -- load_extension errors if the extension was never installed, so this
        -- is conditional rather than unconditional.
        if require("bornguts.devbox").full then
            require('telescope').load_extension('fzf')
        end

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.find_files, {})
        vim.keymap.set('n', '<leader>p', builtin.git_files, {})
        vim.keymap.set('n', '<leader>k', builtin.keymaps, {})
        vim.keymap.set('n', '<leader>f', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>h', builtin.help_tags, {})
    end
}
