" Fish doesn't play all that well with others
set shell=/bin/bash
let mapleader = "\<Space>"

" =============================================================================
" # PLUGINS
" =============================================================================
call plug#begin()
Plug 'machakann/vim-highlightedyank'
call plug#end()

" =============================================================================
" # Keyboard shortcuts
" =============================================================================
" ; as :
nnoremap ; :

" Jump to start and end of line using the home row keys
map H ^
map L $


set clipboard=unnamedplus

" Quick-save
nmap <leader>w :w<CR>

" No arrow keys --- force yourself to use the home row
nnoremap <up> <nop>
nnoremap <down> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Move by line
nnoremap j gj
nnoremap k gk

" Keymap for replacing up to next _ or -
noremap <leader>m ct_

" Move lines up and down in visual mode
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv

