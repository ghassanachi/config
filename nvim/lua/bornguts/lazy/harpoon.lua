return {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
    keys = {
      { "<leader>A", function() require("harpoon"):list():append() end, desc = "harpoon file", },
      { "<C-e>", function() local harpoon = require("harpoon") harpoon.ui:toggle_quick_menu(harpoon:list()) end, desc = "harpoon quick menu", },

      { "<C-h>", function() require("harpoon"):list():select(1) end, desc = "harpoon to file 1", },
      { "<C-j>", function() require("harpoon"):list():select(2) end, desc = "harpoon to file 2", },
      { "<C-k>", function() require("harpoon"):list():select(3) end, desc = "harpoon to file 3", },
      { "<C-l>", function() require("harpoon"):list():select(4) end, desc = "harpoon to file 4", },

      { "<leader><C-h>", function() require("harpoon"):list():replace_at(1) end, desc = "harpoon to file 1", },
      { "<leader><C-j>", function() require("harpoon"):list():replace_at(2) end, desc = "harpoon to file 2", },
      { "<leader><C-k>", function() require("harpoon"):list():replace_at(3) end, desc = "harpoon to file 3", },
      { "<leader><C-l>", function() require("harpoon"):list():replace_at(4) end, desc = "harpoon to file 4", },
    },
}

