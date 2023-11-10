{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.neovim;

  vim-github-copilot = pkgs.vimUtils.buildVimPlugin rec {
    pname = "vim-github-copilot";
    version = "1.11.4";
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "copilot.vim";
      rev = "v${version}";
      sha256 = "sha256-yuaG4kOSXSivFQCvc6iEZP230tlaFoXcZb0WxBjeWdA=";
    };
  };

  vim-github-visincr = pkgs.vimUtils.buildVimPlugin rec {
    pname = "vim-github-visincr";
    version = "20";
    src = pkgs.fetchFromGitHub {
      owner = "vim-scripts";
      repo = "visincr";
      rev = version;
      sha256 = "sha256-2mFYO9KQlO+7DSpTmhpNVVI7Ua0DGJsr+PaYm00e3OE=";
    };
  };

  spellCheckFileTypes = [
    "txt"
    "tex"
    "rst"
    "yaml"
    "html"
    "md"
    "mdx"
    "go"
    "nix"
    "sh"
    "proto"
  ];

  spellCheckWholeFiles = [
    "COMMIT_EDITMSG"
  ];

in {
  options.me.shell.neovim = {
    enable = mkEnableOption "neovim";

    coPilot = {
      enable = mkEnableOption "GitHub Copilot";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "L+ /home/${config.me.username}/.viminfo - - - - /persist/home/.viminfo"
    ] ++ (optionals cfg.coPilot.enable [
      "d /persist/home/.config/github-copilot 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/github-copilot - - - - /persist/home/.config/github-copilot"
    ]);

    environment.variables.EDITOR = "vim";

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        vimv
      ];

      home.sessionVariables = {
        VISUAL = "vim";
      };

      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        defaultEditor = true;

        plugins = (with pkgs.vimPlugins; [
          gruvbox
          vim-airline
          LanguageClient-neovim
          nerdtree
          (mkIf cfg.coPilot.enable vim-github-copilot)
          ack-vim
          fzf-vim
          vim-fugitive
          vim-rhubarb
          indentLine
          vim-lastplace
          vim-dirdiff
          vim-nix
          vim-github-visincr

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
          ]))
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
          hi SpellBad cterm=underline
          ${concatStringsSep "\n"
            (map (s: "autocmd BufNewFile,BufRead " + s + " set spell spelllang=en_gb")
              ((map (s: "*." + s) spellCheckFileTypes) ++ spellCheckWholeFiles)
            )
          }

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

          " highlight word on cursor
          hi CursorLine gui=underline cterm=underline
          autocmd CursorMoved * exe printf('match CursorLine /\V\<%s\>/', escape(expand('<cword>'), '/\'))

          map <C-i> :set conceallevel=0<CR>

          " highlight extra whitespace at the end of a line.
          highlight ExtraWhitespace ctermbg=red guibg=red
          autocmd VimEnter * autocmd WinEnter * let w:created=1
          autocmd VimEnter * let w:created=1
          autocmd WinEnter *
            \ if !exists('w:created') | call matchadd('ExtraWhitespace', '\s\+\%#\@<!$') | endif
          call matchadd('ExtraWhitespace', '\s\+\%#\@<!$')
            "/\s\+\%#\@<!$\

          nnoremap <leader>w!! :w !sudo tee > /dev/null %
        '' + optionalString cfg.coPilot.enable ''
          let g:copilot_node_command = "${pkgs.nodejs}/bin/node"
          let g:copilot_filetypes = {
          \ 'gitcommit': v:true,
          \ 'markdown': v:true,
          \ 'yaml': v:true
          \ }
        '';
      };
    };
  };
}
