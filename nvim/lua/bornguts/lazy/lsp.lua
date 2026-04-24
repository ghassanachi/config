return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
    },

    config = function()
        local cmp = require("cmp")
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        vim.lsp.config('gopls', {
            settings = {
                gopls = {
                    -- Enables `source.organizeImports` as a code action,
                    -- which the autocmd below runs on save.
                    ["local"] = "",
                    gofumpt = true,
                    staticcheck = true,
                },
            },
        })

        -- LSP servers that support `source.organizeImports` expose it as
        -- a code action and rely on the client to invoke it; nothing
        -- happens on save by default. We run it synchronously before
        -- write so the saved buffer already has imports tidied. Python
        -- is handled by conform.nvim (ruff_organize_imports), and
        -- rust-analyzer doesn't expose this action — so the relevant
        -- filetypes here are Go, TypeScript/JavaScript.
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = {
                "*.go",
                "*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts",
            },
            callback = function()
                local params = vim.lsp.util.make_range_params(0, "utf-8")
                params.context = { only = { "source.organizeImports" } }
                local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
                for _, res in pairs(result or {}) do
                    for _, action in pairs(res.result or {}) do
                        if action.edit then
                            vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                        end
                    end
                end
            end,
        })

        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    runtime = {
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        globals = {
                            'vim',
                            'require',
                        },
                    },
                },
            },
        })

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "ts_ls",
            },
        })
        -- Non-LSP tools (formatters/linters) — mason-lspconfig only handles
        -- servers, so CLI tooling used by conform.nvim is installed here.
        require("mason-tool-installer").setup({
            ensure_installed = {
                "oxfmt",
                "oxlint",
                "ruff",
                "stylua",
                "shfmt",
                "jq",
            },
        })


        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                ["<C-d>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                -- Add tab support
                ["<Tab>"] = cmp.mapping.confirm({ select = true }),
                ["<Enter>"] = cmp.mapping.confirm({ select = true }),
            }),
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" }, -- For luasnip users.
                { name = "path" },
            }, {
                { name = "buffer" },
            }),
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end,
}
