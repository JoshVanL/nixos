{ config, lib, pkgs, ... }:

let
  vim-github-copilot = pkgs.vimUtils.buildVimPlugin {
    name = "vim-github-copilot";
    src = pkgs.fetchFromGitHub {
      owner  = "github";
      repo   = "copilot.vim";
      rev    = "c2e75a3a7519c126c6fdb35984976df9ae13f564";
      sha256 = "sha256-V13La54aIb3hQNDE7BmOIIZWy7In5cG6kE0fti/wxVQ=";
    };
  };

in {
  environment.variables = { EDITOR = "vim"; };
  environment.systemPackages = with pkgs; [
    (neovim.override {
      viAlias  = true;
      vimAlias = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            vim-nix
            vim-lastplace
            # TODO:
            #powerline
            gruvbox
            vim-go
            vim-airline
            vim-airline-themes
            indentLine
            vim-trailing-whitespace
            vim-polyglot
            vim-github-copilot
          ];
        };
        customRC = ''
          syntax on
          filetype plugin indent on
          filetype plugin on
          let mapleader = ","
          :set number
          set background=dark
          colorscheme gruvbox

          set tabstop=2     "A tab is 2 spaces
          set softtabstop=2 "Insert 2 spaces when tab is pressed
          set shiftwidth=2  "An indent is 2 spaces
          set expandtab     "Always uses spaces instead of tabs
          set shiftround    "Round indent to nearest shiftwidth multiple
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
          let g:airline_symbols.paste = ''
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

          " Enable wordcount
          let g:airline#extensions#wordcount#enabled = 1
          " Add notes to filetypes
          let g:airline#extensions#wordcount#filetypes = '\vnotes|help|markdown|rst|org|text|asciidoc|tex|mail'

          set mouse=a

          "Spell Checking
          autocmd BufNewFile,BufRead *.txt set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.tex set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.rst set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.yaml set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.html set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.md set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.mdx set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.go set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.nix set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *.sh set spell spelllang=en_gb
          autocmd BufNewFile,BufRead *COMMIT_EDITMSG set spell spelllang=en_gb
          hi SpellBad cterm=underline

          " Allow saving of files as sudo when I forgot to start vim using sudo.
          nnoremap <leader>w!! :w !sudo tee > /dev/null %
          " Go build
          cmap gg GoBuild <CR>
          cmap tt GoTest <CR>
          nmap gi :GoIfErr <CR>
          nmap <C-i> :GoImports <CR>
          let g:go_fmt_autosave = 1

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

          set splitbelow

          :set backspace=indent,eol,start

          " Clipboard
          vmap <C-c> "+y
          vnoremap <C-z> "+x
          vmap <C-x> "+k
          inoremap <C-v> <C-r>*
          xnoremap "+y y:call system("wl-copy", @")<cr>
          nnoremap "+p :let @\"=substitute(system(\"wl-paste --no-newline\"), '<C-v><C-m>', ''+"''"+'', 'g')<cr>p

          set conceallevel=0
          set guicursor=i:block
        '';
      };
    }
  )];
}
