local status, lspconfig = pcall(require, "lspconfig")
if (not status) then return end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local function config(_config, rt)
    return vim.tbl_deep_extend("force", {
        on_attach = function(_, bufnr)
            --Enable completion triggered by <c-x><c-o>
            vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = bufnr })
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = bufnr })
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, { buffer = bufnr })
            vim.keymap.set('n', '<space>r', vim.lsp.buf.rename, { buffer = bufnr })
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr })
            vim.keymap.set('n', '<space>e', vim.lsp.diagnostic.show_line_diagnostics, { buffer = bufnr })
            vim.keymap.set('n', '[d', vim.lsp.diagnostic.goto_prev, { buffer = bufnr })
            vim.keymap.set('n', ']d', vim.lsp.diagnostic.goto_next, { buffer = bufnr })
            vim.keymap.set('n', '<space>q', vim.lsp.diagnostic.set_loclist, { buffer = bufnr })
            vim.keymap.set("n", "<space>f", vim.lsp.buf.formatting, { buffer = bufnr })
            -- Hover actions
            if rt == nil then
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
                vim.keymap.set('n', '<Leader>a', vim.lsp.buf.code_action, { buffer = bufnr })
            else
                vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
                vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
            end
        end,
        capabilities,
    }, _config or {})
end

-- Deno LSP
lspconfig.denols.setup(config({
    init_options = {
        enable = true,
        lint = true,
    }
}))

lspconfig.sumneko_lua.setup(config({
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
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

-- Rust Tools Setup
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
    }, rt),
    tools = {
        inlay_hints = {
            highlight = 'NonText',
        },
    },
})

vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.formatting_sync()]]
