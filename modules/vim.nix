{ config, pkgs, libs, ... }:
let

  vim-buftabline = pkgs.vimUtils.buildVimPlugin {
    name = "vim-buftabline";
    src = pkgs.fetchFromGitHub {
      owner = "ap";
      repo = "vim-buftabline";
      rev = "73b9ef5dcb6cdf6488bc88adb382f20bc3e3262a";
      sha256 = "vmznVGpM1QhkXpRHg0mEweolvCA9nAOuALGN5U6dRO8=";
    };
  };

  vim-snakemake = pkgs.vimUtils.buildVimPlugin {
    name = "vim-snakemake";
    src = pkgs.fetchFromGitHub {
      owner = "snakemake";
      repo = "snakemake";
      rev = "v7.12.0";
      sha256 = "jdqq+0Gz5EWJRzpQmYEJ62Cdf6fkOhW5qle915brfX8=";
    } + "/misc/vim";
  };

in {
  programs.neovim = {
    enable = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-buftabline
      {
        plugin = vim-snakemake;
        config = ''
          au BufNewFile,BufRead snakefile set filetype=snakemake
          set nofoldenable
        '';
      }
      {
        plugin = vim-polyglot;
        config = ''
          let g:vim_svelte_plugin_use_typescript = 1
        '';
      }
      {
        plugin = nvim-base16;
        config = ''
          if filereadable(expand("~/.vimrc_background"))
            let base16colorspace=256
            source ~/.vimrc_background
          else
            colorscheme base16-gruvbox-dark-medium";
          endif
        '';
      }
    ];

    extraConfig = ''
      set list
      set listchars=tab:╰─,trail:·

      set mouse=""
      let mapleader=","

      set number
      let &colorcolumn="80,120"

      nnoremap <A-Tab> :bn<CR>
      nnoremap <A-1> :1b<CR>
      nnoremap <A-2> :2b<CR>
      nnoremap <A-3> :3b<CR>
      nnoremap <A-4> :4b<CR>
      nnoremap <A-5> :5b<CR>
      nnoremap <A-6> :6b<CR>
    '';

  };

}
