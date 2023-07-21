{ config, pkgs, libs, ... }:
let

  vim-buftabline = pkgs.vimUtils.buildVimPlugin rec {
    name = "vim-buftabline";
    pname = name;
    src = pkgs.fetchFromGitHub {
      owner = "ap";
      repo = "vim-buftabline";
      rev = "73b9ef5dcb6cdf6488bc88adb382f20bc3e3262a";
      sha256 = "vmznVGpM1QhkXpRHg0mEweolvCA9nAOuALGN5U6dRO8=";
    };
  };

  vim-snakemake = pkgs.vimUtils.buildVimPlugin rec {
    name = "vim-snakemake";
    pname = name;
    src = pkgs.fetchFromGitHub {
      owner = "snakemake";
      repo = "snakemake";
      rev = "v7.12.0";
      sha256 = "jdqq+0Gz5EWJRzpQmYEJ62Cdf6fkOhW5qle915brfX8=";
    } + "/misc/vim";
  };

  python-importlib-metadata17 = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "importlib-metadata";
    version = "1.7.0";
    format = "pyproject";
    src = pkgs.python3.pkgs.fetchPypi {
      pname = "importlib_metadata";
      inherit version;
      hash = "sha256-kLtljNu/bRc1tjQc5wj8cCSj4U6Z/9xXg+3qn5sHf4M=";
    };
    nativeBuildInputs = with pkgs.python3.pkgs; [ setuptools setuptools-scm ];
    propagatedBuildInputs = with pkgs.python3.pkgs; [ toml zipp ];
    doCheck = false;
  };

  python-snakefmt = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "snakefmt";
    version = "0.8.4";
    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "snakemake";
      repo = "snakefmt";
      rev = "v${version}";
      sha256 = "sha256-rQe2BgX9qNEZV4FfvGHzLHqeRI9Xq3Gm3XozekQjHwo=";
    };
    #doCheck = false;
    preBuild = ''
        sed -i 's/requires = ["poetry>=0.12"]/requires = ["poetry-core"]/g' pyproject.toml
        sed -i 's/build-backend = "poetry.masonry.api"/build-backend = "poetry.core.masonry.api"/g' pyproject.toml
    '';
    nativeBuildInputs = [ pkgs.python3.pkgs.poetry-core ];
    propagatedBuildInputs = with pkgs.python3.pkgs; [
      black
      python-importlib-metadata17
    ];
  };

in {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;

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
      {
        plugin = neoformat;
        config = ''
          let g:neoformat_enabled_python = ['black']
          let g:neoformat_enabled_nix = ['alejandra']

          let g:neoformat_snakemake_snakefmt = {
            \ 'exe': '${python-snakefmt}/bin/snakefmt',
            \ 'args': ['-'],
            \ 'stdin': 1,
            \ }
          let g:neoformat_enabled_snakemake = ['snakefmt']
        '';
      }
    ];

    extraPackages = with pkgs; [
      rustfmt
      black
      alejandra
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

      nnoremap <leader>y :Neoformat<CR>
    '';

  };

}
