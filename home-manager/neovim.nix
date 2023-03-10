{ config, lib, pkgs, ... }:

with lib;
let
  vim-github-copilot = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-github-copilot";
    version = "1.8.3";
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "copilot.vim";
      rev = "9e869d29e62e36b7eb6fb238a4ca6a6237e7d78b";
      sha256 = "sha256-B+2hHNTrabj6O9F6OoskNIUsjJXLrt+4XgjuiRoM80s=";
    };
  };

  vim-codegpt = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-codegpt";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "dpayne";
      repo = "codegpt.nvim";
      rev = "53b3e75af4ddd281d09fcd9574f8cebdf3198010";
      sha256 = "sha256-boegd5ypU7k7tn3y78XguIV1ri4XyY9zfewQ9nLavfs=";
    };
  };

in {
  # Required for GitHub copilot.
  home.packages = [ pkgs.nodejs-16_x ];

  home.sessionVariables = {
    # TODO: pass as arg
    OPENAI_API_KEY="$(cat /persist/home/secrets/chatgpt/api_key)";
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = (with pkgs.vimPlugins; [
      gruvbox
      vim-airline
      LanguageClient-neovim
      nerdtree
      vim-github-copilot
      ack-vim
      fzf-vim
      vim-fugitive
      vim-rhubarb
      indentLine
      vim-trailing-whitespace
      vim-lastplace

      vim-codegpt
      # needed for codegpt
      plenary-nvim
      nui-nvim

      (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with pkgs.tree-sitter-grammars; [
        tree-sitter-beancount
        tree-sitter-dockerfile
        tree-sitter-gomod
        tree-sitter-html
        tree-sitter-json
        tree-sitter-make
        tree-sitter-markdown
        tree-sitter-nix
        tree-sitter-yaml
      ]
      ))
    ]);

    extraConfig = ''
      " No temporary files in working directories
      set backupdir=~/.vim/backup//
      set directory=~/.vim/swap//
      set undodir=~/.vim/undo//

      " General settings
      set backspace=indent,eol,start
      set number
      set showcmd
      set incsearch
      set hlsearch
      set noshowmode

      " Required for operations modifying multiple buffers like rename.
      set hidden

      " Display position coordinates in bottom right
      set ruler

      " Abbreviate messages and disable intro screen
      set shortmess=AtI

      " Automatically expand tabs into spaces
      set expandtab

      " Tabs are four spaces
      set shiftwidth=2
      set softtabstop=2
      set tabstop=2

      set splitbelow

      let mapleader=","

      " Set the colorscheme
      set background=dark
      colorscheme gruvbox

      "" vim-airline settings
      set laststatus=2
      let g:airline_powerline_fonts = 1
      let g:airline_detect_paste=1

      lua << EOF
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
          disable = {},
        },
        indent = {
          enable = true,
          disable = {},
        },
      }
      EOF

      set guicursor=i:block

      "Spell Checking
      autocmd BufNewFile,BufRead *.txt set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.tex set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.rst set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.yaml set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.html set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.md set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.mdx set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.go set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.go setlocal omnifunc=go#complete#Complete
      autocmd BufNewFile,BufRead *.nix set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.sh set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *.proto set spell spelllang=en_gb
      autocmd BufNewFile,BufRead *COMMIT_EDITMSG set spell spelllang=en_gb
      hi SpellBad cterm=underline

      :set backspace=indent,eol,start
      let g:indentLine_char = '¦'

      "word wrap 80 chars for md files
      au BufRead,BufNewFile *.md setlocal textwidth=80
      au BufRead,BufNewFile *.tex setlocal textwidth=80
      au BufRead,BufNewFile *.rst setlocal textwidth=80
      au BufRead,BufNewFile *.txt setlocal textwidth=80

      " Clipboard
      vmap <C-c> "+y
      vnoremap <C-z> "+x

      map <C-i> :set conceallevel=0<CR>

      nnoremap <leader>w!! :w !sudo tee > /dev/null %

      let g:copilot_filetypes = {
      \ 'gitcommit': v:true,
      \ 'markdown': v:true,
      \ 'yaml': v:true
      \ }
    '';
  };
}
