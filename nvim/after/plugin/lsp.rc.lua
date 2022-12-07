local status, lspconfig = pcall(require, "lspconfig")
if (not status) then return end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local nnoremap = require("guts.core.keymap").nnoremap

local function config(_config, rt)
    return vim.tbl_deep_extend("force", {
        on_attach = function(_, bufnr)
            --Enable completion triggered by <c-x><c-o>
            vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

            nnoremap('gd', vim.lsp.buf.definition, { buffer = bufnr })
            nnoremap('gi', vim.lsp.buf.implementation, { buffer = bufnr })
            nnoremap('<C-k>', vim.lsp.buf.signature_help, { buffer = bufnr })
            nnoremap('<space>D', vim.lsp.buf.type_definition, { buffer = bufnr })
            nnoremap('<space>r', vim.lsp.buf.rename, { buffer = bufnr })
            nnoremap('gr', vim.lsp.buf.references, { buffer = bufnr })
            nnoremap('<space>e', vim.diagnostic.open_float, { buffer = bufnr })
            nnoremap('[d', vim.diagnostic.goto_prev, { buffer = bufnr })
            nnoremap(']d', vim.diagnostic.goto_next, { buffer = bufnr })
            nnoremap("<space>f", vim.lsp.buf.format, { buffer = bufnr })
            ---- Hover actions
            if rt == nil then
                nnoremap('K', vim.lsp.buf.hover, { buffer = bufnr })
                nnoremap('<Leader>a', vim.lsp.buf.code_action, { buffer = bufnr })
            else
                nnoremap("K", rt.hover_actions.hover_actions, { buffer = bufnr })
                nnoremap("<Leader>a", rt.code_action_group.code_action_group,
                    { buffer = bufnr })
            end
        end,
        capabilities = capabilities,
    }, _config or {})
end

-- Deno LSP
lspconfig.denols.setup(config({
    init_options = {
        enable = true,
        lint = true,
    }
}))

-- Typescript/Web LSP
lspconfig.tsserver.setup(config({
    filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
    -- Remove .git root_dir option to not conflict with denols
    root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json")
}))
lspconfig.svelte.setup(config())
lspconfig.tailwindcss.setup(config())
-- lspconfig.cssls.setup(config())
lspconfig.astro.setup(config())

-- Lua LSP
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

vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
