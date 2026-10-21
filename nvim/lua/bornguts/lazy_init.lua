-- Bootstrap lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = "bornguts.lazy",
	change_detection = { notify = false },
	install = {
		colorscheme = { "gruvbox" },
	},
	-- plenary.nvim ships a rockspec, so lazy tries to install it through
	-- luarocks/hererocks, which needs a Lua 5.1 build that dev boxes do not
	-- have. It fails noisily on every startup and then builds from source
	-- anyway, which is all we need -- so skip straight to that.
	rocks = { enabled = false },
})
