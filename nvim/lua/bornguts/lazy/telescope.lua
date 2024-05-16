return {
    "nvim-telescope/telescope.nvim",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({})

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.find_files, {})
        vim.keymap.set('n', '<leader>p', builtin.git_files, {})
        vim.keymap.set('n', '<leader>k', builtin.keymaps, {})
        vim.keymap.set('n', '<leader>g', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>G', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>h', builtin.help_tags, {})
    end
}
