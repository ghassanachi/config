local status, cmp = pcall(require, "cmp")
if (not status) then return end



cmp.setup({
    -- Enable LSP snippets
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        -- Add tab support
        ['<Tab>'] = cmp.mapping.confirm({ select = true }),
        ['<C-e>'] = cmp.mapping.close(),
    },
    -- Installed sources:
    sources = {
        { name = 'path' }, -- file paths
        { name = 'nvim_lsp' }, -- from language server
        { name = 'nvim_lsp_signature_help' }, -- display function signatures with current parameter emphasized
        { name = 'nvim_lua' }, -- complete neovim's Lua runtime API such vim.lsp.*
        { name = 'buffer' }, -- source current buffer
        { name = 'vsnip' }, -- nvim-cmp source for vim-vsnip
    },
    experimental = {
        ghost_text = true,
    },
    window = {
        documentation = cmp.config.window.bordered(),
    },
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})
