local status, lspconfig = pcall(require, "lspconfig")
if (not status) then return end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

local function config(_config)
    return vim.tbl_deep_extend("force", {
        on_attach = function(_, bufnr)
            --Enable completion triggered by <c-x><c-o>
            vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr })
            vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
            vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr })
            vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { buffer = bufnr })
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = bufnr })
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr })
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr })
            vim.keymap.set("n", "<leader>h", vim.lsp.buf.signature_help, { buffer = bufnr })
            vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
            vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { buffer = bufnr })
            -- vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, { buffer = bufnr })
        end,
        capabilities = capabilities,
    }, _config or {})
end

vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.formatting_sync()]]

-- Deno Lsp
--lspconfig.denols.setup(config({
--    init_options = {
--        enable = true,
--        lint = true,
--    }
--}))

-- Typescript/Web Lsp
lspconfig.tsserver.setup(config({
    -- Remove .git root_dir option to not conflict with denols
    root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json")
}))

-- Svelte Lsp
lspconfig.svelte.setup(config())

-- Tailwind Lsp
lspconfig.tailwindcss.setup(config())

-- Lua LSP
lspconfig.sumneko_lua.setup(config({
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you"re using (most likely LuaJIT in the case of Neovim)
                version = "LuaJIT",
                -- Setup your lua path
                path = vim.split(package.path, ";"),
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { "vim" },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                },
            },
        },
    },
}))


-- Rust Tools Setup (unused)

local rtstatus, rt = pcall(require, "rust-tools")
if (not rtstatus) then return end

rt.setup({
    server = config({
        settings = {
            ["rust-analyser"] = {
                cargo = {
                    allFeatures = true,
                },
                completion = {
                    postfix = {
                        enable = false,
                    },
                },
                checkOnSave = {
                    command = "clippy",
                },
                inlayHints = {
                    lifetimeElisionHints = {
                        enable = "skip_trivial"
                    },
                    reborrowHints = {
                        enable = "always"
                    }
                }
            }
        }
    }),
    tools = {
        inlay_hints = {
            auto = true,
            show_parameter_hints = false,
            highlight = "NonText",
        },
    },
})
