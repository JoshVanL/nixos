{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.neovim;

  vim-github-copilot = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-github-copilot";
    version = "1.8.4";
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "copilot.vim";
      rev = "1358e8e45ecedc53daf971924a0541ddf6224faf";
      sha256 = "sha256-6xIOngHzmBrgNfl0JI5dUkRLGlq2Tf+HsUj5gha/Ppw=";
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
  options.me.shell.neovim = {
    enable = mkEnableOption "neovim";

    coPilot = {
      enable = mkEnableOption "GitHub Copilot";
    };
    openAI = {
      enable = mkEnableOption "OpenAI";
      apiKeyPath = mkOption {
        type = types.path;
        default = "";
        description = "OpenAI API key";
      };
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
          vim-trailing-whitespace
          vim-lastplace
          vim-dirdiff

          (mkIf cfg.openAI.enable vim-codegpt)
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

          "highlight trailing whitespace
          :highlight ExtraWhitespace ctermbg=red guibg=red
          :match ExtraWhitespace /\s\+$/

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
          autocmd BufNewFile,BufRead *.nix set spell spelllang=en_gb
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
        '' + optionalString cfg.coPilot.enable ''
          let g:copilot_node_command = "${pkgs.nodejs}/bin/node"
          let g:copilot_filetypes = {
          \ 'gitcommit': v:true,
          \ 'markdown': v:true,
          \ 'yaml': v:true
          \ }
        ''+ optionalString cfg.openAI.enable ''
          let $OPENAI_API_KEY = readfile('${cfg.openAI.apiKeyPath}')[0]
        '';
      };
    };
  };
}
