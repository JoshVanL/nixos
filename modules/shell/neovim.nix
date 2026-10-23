{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.neovim;

  vim-github-copilot = pkgs.vimUtils.buildVimPlugin rec {
    pname = "vim-github-copilot";
    version = "1.56.0";
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "copilot.vim";
      rev = "v${version}";
      sha256 = "sha256-dL+yxTPSjX5PDJ4LgqFoS1HtkZV9G1S6VD+w+CPhil8=";
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
    "cs"
    "js"
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
    # diagram.nvim has an unfree licence.
    me.nixpkgs.allowedUnfree = [ "diagram.nvim" ];

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
        # mermaid diagram rendering in markdown via diagram.nvim
        mermaid-cli
        imagemagick
        # terminal character art rendering of mermaid diagrams (pkgs/mmd)
        mmd
      ];

      programs.neovim = {
        # No plugin here needs the Python or Ruby provider.
        withPython3 = false;
        withRuby = false;
        enable = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        defaultEditor = true;

        # lua bindings to imagemagick, required by image-nvim
        extraLuaPackages = ps: [ ps.magick ];

        plugins = (with pkgs.vimPlugins; [
          gruvbox
          vim-airline
          #LanguageClient-neovim
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
          nvim-colorizer-lua
          image-nvim
          diagram-nvim

          (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with pkgs.tree-sitter-grammars; [
            tree-sitter-beancount
            tree-sitter-dockerfile
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

          " nvim-colorizer requires this at setup time; both terminals support true colour.
          set termguicolors

          " nixpkgs' grammar bundle ships each grammar's upstream queries, which
          " use predicates nvim-treesitter no longer defines (#is-not?). Put the
          " plugin's curated queries first so they win.
          set runtimepath^=${pkgs.vimPlugins.nvim-treesitter}/runtime

          lua << EOF
          -- nvim-treesitter has no 'configs' module. Highlighting and
          -- indentation are enabled per buffer when a
          -- parser for the filetype is installed.
          vim.api.nvim_create_autocmd('FileType', {
            callback = function(args)
              if pcall(vim.treesitter.start, args.buf) then
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end,
          })
          require 'colorizer'.setup()

          -- Render mermaid blocks in markdown as inline images (kitty
          -- graphics protocol). Only inside ghostty: alacritty has no image
          -- protocol and would display the escape sequences as garbage. Use
          -- `mmd <file>` for terminal-agnostic character art rendering.
          if os.getenv("GHOSTTY_RESOURCES_DIR") then
            require("image").setup({
              backend = "kitty",
            })
            require("diagram").setup({
              integrations = {
                require("diagram.integrations.markdown"),
              },
              renderer_options = {
                mermaid = {
                  theme = "dark",
                  background = "transparent",
                },
              },
            })
          end
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
          let g:indentLine_conceallevel=0

          "word wrap 80 chars for md files
          au BufRead,BufNewFile *.tex setlocal textwidth=80
          au BufRead,BufNewFile *.rst setlocal textwidth=80
          au BufRead,BufNewFile *.txt setlocal textwidth=80

          " Clipboard
          vmap <C-c> "+y
          vnoremap <C-z> "+x
          " cut to system clipboard
          nnoremap <C-x> "+d
          xnoremap <C-x> "+d

          " highlight word on cursor
          hi CursorLine gui=underline cterm=underline
          autocmd CursorMoved * exe printf('match CursorLine /\V\<%s\>/', escape(expand('<cword>'), '/\'))

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
