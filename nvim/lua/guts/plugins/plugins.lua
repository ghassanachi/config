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
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
    }
    use 'airblade/vim-rooter'
    use 'windwp/nvim-autopairs'
    use 'windwp/nvim-ts-autotag'
    use 'mbbill/undotree'
    --  use 'numToStr/Comment.nvim'

    -- Visual Enhancements
    use 'nvim-lualine/lualine.nvim' -- Statusline
    use 'machakann/vim-highlightedyank' -- Hilighted yank
    use 'kyazdani42/nvim-web-devicons' -- File icons
    use 'norcalli/nvim-colorizer.lua'

    -- Color Scheme
    use { "ellisonleao/gruvbox.nvim" }

    -- LSP Configuration
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'neovim/nvim-lspconfig'
    use 'simrat39/rust-tools.nvim'

    -- Completion Configuration
    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-nvim-lsp'
    use 'onsails/lspkind.nvim'

    -- Useful completion sources:
    use 'hrsh7th/cmp-nvim-lua'
    use 'hrsh7th/cmp-nvim-lsp-signature-help'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-buffer'

    -- Snippet source for cmp
    use 'hrsh7th/cmp-vsnip'
    use 'hrsh7th/vim-vsnip'

    -- Debugging
    use 'mfussenegger/nvim-dap'
    use("rcarriga/nvim-dap-ui")
    use("theHamsta/nvim-dap-virtual-text")

    -- Treesitter Context Info and Playground
    use("nvim-treesitter/playground")
    -- use("nvim-treesitter/nvim-treesitter-context")

    -- Git Support
    -- use 'lewis6991/gitsigns.nvim'
    -- use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

    if packer_bootstrap then
        packer.sync()
    end

end)
