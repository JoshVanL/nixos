{ config, pkgs, ...}:

{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox
      vim-go
      vim-airline
      vim-airline-themes
      indentLine
      vim-trailing-whitespace
    ];
    extraConfig = ''
    syntax on
    filetype plugin indent on
    filetype plugin on
    let mapleader = ","
    :set number
    set background=dark
    colorscheme gruvbox

    " Clipboard
    vmap <C-c> "+y
    vmap <C-x> "+k

    set tabstop=2                   "A tab is 2 spaces
    set softtabstop=2               "Insert 2 spaces when tab is pressed
    set shiftwidth=2                "An indent is 2 spaces
    set expandtab                   "Always uses spaces instead of tabs
    set shiftround                  "Round indent to nearest shiftwidth multiple
    set laststatus=2
    set t_Co=256
    set encoding=utf-8

    let g:airline_powerline_fonts = 1
    let g:airline_theme='gruvbox'
    let g:powerline_symbols = "fancy"
    set guifont=Source\ Code\ Pro\ for\ Powerline "make sure to escape the spaces in the name properly"
    if !exists('g:airline_symbols')
        let g:airline_symbols = {}
    endif
    if !exists("g:syntax_on")
        syntax enable
    endif
    " unicode symbols
    let g:airline_left_sep = '»'
    let g:airline_left_sep = '▶'
    let g:airline_right_sep = '«'
    let g:airline_right_sep = '◀'
    let g:airline_symbols.linenr = '␊'
    let g:airline_symbols.linenr = '␤'
    let g:airline_symbols.linenr = '¶'
    let g:airline_symbols.branch = '⎇'
    let g:airline_symbols.paste = 'ρ'
    let g:airline_symbols.paste = 'Þ'
    let g:airline_symbols.paste = '∥'
    let g:airline_symbols.whitespace = 'Ξ'
    " airline symbols
    let g:airline_left_sep = ''
    let g:airline_left_alt_sep = ''
    let g:airline_right_sep = ''
    let g:airline_right_alt_sep = ''
    let g:airline_symbols.branch = ''
    let g:airline_symbols.readonly = ''
    let g:airline_symbols.linenr = ''
    set ttimeoutlen=20

    :set noshowmode
    "Mouse moves splits
    set mouse=a
    "Terminal
    set splitbelow
    let g:ConqueTerm_StartMessages = 0
    map <S-t> :split <CR> :resize 10 <CR> :ConqueTerm bash <CR>

    map <C-w> <C-w><C-w>

    "Spell Checking
    autocmd BufNewFile,BufRead *.txt set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.tex set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.rst set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.yaml set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.html set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.md set spell spelllang=en_gb
    autocmd BufNewFile,BufRead *.go set spell spelllang=en_gb

    " Allow saving of files as sudo when I forgot to start vim using sudo.
    cmap w!! w !sudo tee > /dev/null %
    " Go build
    cmap gg GoBuild <CR>
    cmap tt GoTest <CR>
    nmap gi :GoIfErr <CR>
    nmap <C-i> :GoImports <CR>
    let g:go_fmt_autosave = 1

    " Copy/Paste to system clipboard
    vmap <C-c> "+y
    vmap <C-x> "+c
    imap <C-v> <ESC>"+pa

    "Indent Line char
    let g:indentLine_char = '¦'
    "Highlight search
    set hlsearch
    nnoremap <silent> <C-l> :nohl<CR><C-l>

    "word wrap 80 chars for md files
    au BufRead,BufNewFile *.md setlocal textwidth=80
    au BufRead,BufNewFile *.tex setlocal textwidth=80
    au BufRead,BufNewFile *.rst setlocal textwidth=80
    au BufRead,BufNewFile *.txt setlocal textwidth=80

    let g:go_highlight_types = 1
    let g:go_highlight_fields = 1
    let g:go_highlight_functions = 1
    let g:go_highlight_function_calls = 1
    let g:go_highlight_extra_types = 1

    " CTRL-x is Cut TODO
    vnoremap <C-z> "+x
    :set paste
    '';
  };
}
