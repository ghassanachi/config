local lsp_status, lsp = pcall(require, "lsp-zero")
if (not lsp_status) then return end

local cmp_status, cmp = pcall(require, "cmp");
if (not cmp_status) then return end

local lspconfig = require('lspconfig')

lsp.preset("recommended")

lsp.ensure_installed({
    'denols',
    'tsserver',
    'eslint',
    'lua_ls',
    'rust_analyzer',
    'yamlls',
    'svelte',
})

local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ["<C-u>"] = cmp.mapping.scroll_docs( -4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    -- Add tab support
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
})


lsp.set_preferences({
    sign_icons = {}
})

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<C-h>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
            end,
        })
    end
end

lsp.on_attach(on_attach)

-- Language configurations
-- Lua (Add vim global)
lsp.configure('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})

-- Yaml with Schema Store and AWS CFN Tags
lsp.configure('yamlls', {
    settings = {
        yaml = {
            schemaStore = {
                enable = true
            },
        },
    },
})

lsp.configure('denols', {
    root_dir = lspconfig.util.root_pattern('deno.json', "deno.jsonc"),
})

lsp.configure("tsserver", {
    root_dir = lspconfig.util.root_pattern('package.json'),
    single_file_support = false,
})

lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
})

local status, null_ls = pcall(require, "null-ls")
if (not status) then return end

null_ls.setup({
    on_attach = on_attach,
    sources = {
        null_ls.builtins.formatting.prettier,
    },
})
