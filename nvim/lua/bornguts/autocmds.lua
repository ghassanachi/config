-- ==============================================================================
-- Autocommands
-- ==============================================================================
--
-- Central home for all autocommands. Grouping them here (rather than scattering
-- them across init.lua and plugin files) keeps event-driven behaviour
-- discoverable and lets us clear/redefine the groups idempotently on reload.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Shared group for our own autocommands. Passing `{ clear = true }` (the
-- default) means re-sourcing this file wipes previously registered commands
-- instead of stacking duplicates.
local BornGutsGroup = augroup('BornGutsGroup', {})

-- ------------------------------------------------------------------------------
-- Highlight on yank
-- ------------------------------------------------------------------------------

-- Briefly flash yanked text so it's obvious what was copied.
local yank_group = augroup('HighlightYank', {})
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
        })
    end,
})

-- ------------------------------------------------------------------------------
-- Trim trailing whitespace on save
-- ------------------------------------------------------------------------------

autocmd({ "BufWritePre" }, {
    group = BornGutsGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- ------------------------------------------------------------------------------
-- Soft-wrap prose files
-- ------------------------------------------------------------------------------

-- We keep the global default of `wrap = false` (see set.lua) and only enable
-- wrapping for markdown, breaking at word boundaries (`linebreak`) so prose
-- reads naturally. Buffer-local `j`/`k` maps move by visual line so navigation
-- tracks the wrapped display rather than jumping over whole paragraphs, while a
-- count (e.g. `5j`) still moves by real lines so relative-number jumps work.
-- We apply the same maps in visual/visual-block mode (`x`) so selecting prose
-- moves by display line too, keeping selection behaviour consistent with normal
-- mode.
autocmd('FileType', {
    group = BornGutsGroup,
    pattern = { 'markdown' },
    callback = function(e)
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true

        local opts = { buffer = e.buf, expr = true }
        vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", opts)
        vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", opts)
    end,
})

-- ------------------------------------------------------------------------------
-- LSP keymaps
-- ------------------------------------------------------------------------------

-- Bind LSP actions only once a server actually attaches to the buffer, so the
-- maps exist exactly where they're useful.
autocmd('LspAttach', {
    group = BornGutsGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
    end
})
