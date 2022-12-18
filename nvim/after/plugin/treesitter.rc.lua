local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

-- Treesitter Plugin Setup
ts.setup {
    ensure_installed = { "help", "javascript", "typescript", "lua", "rust", "toml" },
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    ident = { enable = true },
    rainbow = {
        enable = true,
        extended_mode = true,
        max_file_lines = nil,

    }
}
