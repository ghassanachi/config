return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme gruvbox]])
		-- Make comments more prominent -- they are important.
		local bools = vim.api.nvim_get_hl(0, { name = "Boolean" })
		vim.api.nvim_set_hl(0, "Comment", bools)
	end,
}
