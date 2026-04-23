return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            -- Customize or remove this keymap to your liking
            "<leader>F",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    -- Everything in opts will be passed to setup()
    opts = {
        -- Define your formatters
        formatters_by_ft = {
            lua = { "stylua" },
            -- Ruff replaces isort + black + (some) flake8 rules. Order matters:
            -- fixes/imports rewrite code, format does the final whitespace pass.
            python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
            -- oxfmt is a Prettier-compatible formatter from the oxc project.
            javascript = { "oxfmt" },
            javascriptreact = { "oxfmt" },
            typescript = { "oxfmt" },
            typescriptreact = { "oxfmt" },
            json = { "oxfmt" },
            jsonc = { "oxfmt" },
            json5 = { "oxfmt" },
            yaml = { "oxfmt" },
            toml = { "oxfmt" },
            css = { "oxfmt" },
            scss = { "oxfmt" },
            less = { "oxfmt" },
            html = { "oxfmt" },
            vue = { "oxfmt" },
            markdown = { "oxfmt" },
            graphql = { "oxfmt" },
        },
        -- Set up format-on-save
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
        -- Customize formatters
        formatters = {
            shfmt = {
                prepend_args = { "-i", "2" },
            },
        },
    },
    init = function()
        -- If you want the formatexpr, here is the place to set it
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}
