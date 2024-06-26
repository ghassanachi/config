local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

-- Treesitter Plugin Setup
ts.setup {
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    autotag = {
        enable = true
    },
    ident = { enable = true },
    rainbow = {
        enable = true,
        extended_mode = true,
        max_file_lines = nil,

    },
}

local tsc_status, treesitter_context = pcall(require, "treesitter-context")
if (not tsc_status) then return end
treesitter_context.setup {}
