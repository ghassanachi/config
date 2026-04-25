return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		vim.cmd([[colorscheme gruvbox]])
		-- Make comments more prominent -- they are important.
		local bools = vim.api.nvim_get_hl(0, { name = "Boolean" })
		vim.api.nvim_set_hl(0, "Comment", bools)

		-- Readable diff colors for `nvim -d`. Gruvbox's defaults paint the
		-- entire changed line with a bright background that hides the text.
		-- Use darker tinted backgrounds and keep the foreground NONE so
		-- normal syntax colors show through; reserve the stronger hue for
		-- DiffText (the actual intra-line change).
		local diff_hl = {
			DiffAdd = { bg = "#2e4b35", fg = "NONE" }, -- dark green
			DiffDelete = { bg = "#4b2e2e", fg = "NONE" }, -- dark red
			DiffChange = { bg = "#3a3a28", fg = "NONE" }, -- dark yellow
			DiffText = { bg = "#7c6f1d", fg = "#ebdbb2", bold = true },
		}
		for group, opts in pairs(diff_hl) do
			vim.api.nvim_set_hl(0, group, opts)
		end
	end,
}
