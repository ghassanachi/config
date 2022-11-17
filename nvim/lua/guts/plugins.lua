local status, packer = pcall(require, "packer")
if not status then
	print("Packer is not installed")
	return
end

-- Reloads Neovim after whenever you save plugins.lua
vim.cmd([[
    augroup packer_user_config
      autocmd!
     autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup END
]])

packer.startup(function(use)
    use 'wbthomason/packer.nvim'

    -- General Utilities
    use 'justinmk/vim-sneak'
    use 'nvim-lua/popup.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'
    use 'nvim-telescope/telescope-fzy-native.nvim'
    use {
      'nvim-treesitter/nvim-treesitter',
      run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
    }
    use 'airblade/vim-rooter'
    use 'windwp/nvim-autopairs'
    use 'windwp/nvim-ts-autotag'

    -- Visual Enhancements
    use 'nvim-lualine/lualine.nvim' -- Statusline
    use 'machakann/vim-highlightedyank' -- Hilighted yank
    use 'kyazdani42/nvim-web-devicons' -- File icons
    use 'norcalli/nvim-colorizer.lua'

    -- Color Scheme
    use("gruvbox-community/gruvbox")

    -- LSP Configuration
    use 'williamboman/mason.nvim'    
    use 'williamboman/mason-lspconfig.nvim'
    use 'neovim/nvim-lspconfig' -- LSP
    use 'simrat39/rust-tools.nvim'

    -- Completion Configuration
    use 'hrsh7th/nvim-cmp' 
    use 'hrsh7th/cmp-nvim-lsp'
    use 'onsails/lspkind.nvim'
    -- Useful completion sources:
    use 'hrsh7th/cmp-nvim-lua'
    use 'hrsh7th/cmp-nvim-lsp-signature-help'
    use 'hrsh7th/cmp-vsnip'                             
    use 'hrsh7th/cmp-path'                              
    use 'hrsh7th/cmp-buffer'                            
    use 'hrsh7th/vim-vsnip'

    -- Snippet source for cmp
    use 'hrsh7th/cmp-vsnip'
    use 'hrsh7th/vim-vsnip'

    -- Debugging
    use 'mfussenegger/nvim-dap'

    -- Git Support
    use 'lewis6991/gitsigns.nvim'
    use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

    if packer_bootstrap then
		packer.sync()
	end

end)
