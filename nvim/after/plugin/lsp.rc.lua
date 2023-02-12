local lsp_status, lsp = pcall(require, "lsp-zero")
if (not lsp_status) then return end
local cmp_status, cmp = pcall(require, "cmp");
if (not cmp_status) then return end

lsp.preset("recommended")

lsp.ensure_installed({
    'tsserver',
    'eslint',
    'lua_ls',
    'rust_analyzer',
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
        ['<C-e>'] = cmp.mapping.close(),
    })


lsp.set_preferences({
    sign_icons = {}
})

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>h", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_create_autocmd("BufWritePre", {
            desc = "Auto format before save",
            pattern = "<buffer>",
            callback = vim.lsp.buf.formatting_sync,
        })
    end
end)

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

lsp.setup()
