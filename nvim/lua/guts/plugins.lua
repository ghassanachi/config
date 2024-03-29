local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    -- General Utilities
    use 'nvim-lua/plenary.nvim'
    use {
        'nvim-telescope/telescope.nvim',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }
    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
    use 'nvim-treesitter/playground'
    use {
        "ahmedkhalf/project.nvim",
        config = function()
            require("project_nvim").setup {
                patterns = { ".git" },
            }
        end
    }
    use 'windwp/nvim-autopairs'
    use 'windwp/nvim-ts-autotag'
    use 'mbbill/undotree'

    -- Visual Enhancements
    use 'nvim-lualine/lualine.nvim'     -- Statusline
    use 'machakann/vim-highlightedyank' -- Hilighted yank
    use 'kyazdani42/nvim-web-devicons'  -- File icons
    use 'norcalli/nvim-colorizer.lua'
    use 'folke/zen-mode.nvim'

    -- Color Scheme
    use "ellisonleao/gruvbox.nvim"

    -- LSP Configuration
    use 'jose-elias-alvarez/null-ls.nvim'
    use "ray-x/lsp_signature.nvim"
    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'hrsh7th/cmp-nvim-lsp-signature-help' },


            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }

    -- Git Support
    -- use 'lewis6991/gitsigns.nvim'
    -- use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

    if packer_bootstrap then
        require('packer').sync()
    end
end)
