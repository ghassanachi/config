return {
    -- No `name = "plenary"` here: telescope, harpoon and neotest all depend on
    -- "nvim-lua/plenary.nvim", and the rename made lazy treat the renamed spec
    -- and the dependency as two different plugins. That installed plenary
    -- twice (both names are in lazy-lock.json) and produced "Too many rounds
    -- of missing plugins" on every start.
    "nvim-lua/plenary.nvim",

    "eandrju/cellular-automaton.nvim",
}

