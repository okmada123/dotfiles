syntax on
command R :w | ! %:p
:set nu
:set paste " on macos (maybe not exclusively) to fix pasting
:set incsearch
:set hlsearch
:set ignorecase

" indentation and tabs
"set ts=4 sw=4
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" move lines
vnoremap <C-j> :m '<-2<CR>gv=gv
vnoremap <C-k> :m '>+1<CR>gv=gv
nmap k :m +1<CR>
nmap j :m -2<CR>

" ctrl-c copies selection to the system clipboard
" vmap <C-c> "+y

" y in visual mode copies selection to the system clipboard
" (and still also 'yanks' the lines, so 'p' works afterwards)
if has('mac') || has('macunix')
  vnoremap y "+y
endif
