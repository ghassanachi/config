return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	-- Skipped on a dev box: :TSUpdate compiles parsers, which needs a C
	-- toolchain. See lua/bornguts/devbox.lua.
	enabled = require("bornguts.devbox").full,
	build = ":TSUpdate",
	lazy = false,
	config = function()
		require("nvim-treesitter").setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		-- Install parsers
		require("nvim-treesitter").install({
			"vimdoc",
			"javascript",
			"typescript",
			"c",
			"lua",
			"rust",
			"jsdoc",
			"bash",
			"go",
			"gomod",
			"gosum",
		})

		-- Enable highlighting and indentation per filetype
		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"vimdoc",
				"javascript",
				"typescript",
				"c",
				"lua",
				"rust",
				"jsdoc",
				"bash",
				"go",
				"gomod",
				"gosum",
			},
			callback = function()
				-- Highlighting
				vim.treesitter.start()
				-- Indentation
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				-- Folding (optional)
				-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end,
		})
	end,
}
