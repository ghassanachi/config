return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup()

		vim.keymap.set("n", "<leader>t", function()
			harpoon:list():add()
		end, { desc = "Harpoon Buffer" })
		vim.keymap.set("n", "<C-t>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Open Harpoon" })

		vim.keymap.set("n", "<C-h>", function()
			harpoon:list():select(1)
		end, { desc = "Go to Harpoon 1" })
		vim.keymap.set("n", "<C-j>", function()
			harpoon:list():select(2)
		end, { desc = "Go to Harpoon 2" })
		vim.keymap.set("n", "<C-k>", function()
			harpoon:list():select(3)
		end, { desc = "Go to Harpoon 3" })
		vim.keymap.set("n", "<C-l>", function()
			harpoon:list():select(4)
		end, { desc = "Go to Harpoon 4" })
		vim.keymap.set("n", "<leader><C-h>", function()
			harpoon:list():replace_at(1)
		end, { desc = "Replace Harpoon 1" })
		vim.keymap.set("n", "<leader><C-j>", function()
			harpoon:list():replace_at(2)
		end, { desc = "Replace Harpoon 2" })
		vim.keymap.set("n", "<leader><C-k>", function()
			harpoon:list():replace_at(3)
		end, { desc = "Replace Harpoon 3" })
		vim.keymap.set("n", "<leader><C-s>", function()
			harpoon:list():replace_at(4)
		end, { desc = "Replace Harpoon 4" })
	end,
}
