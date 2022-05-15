{ config, pkgs, libs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      vim-nix
      {
        plugin = nvim-base16;
        config = "colorscheme base16-gruvbox-dark-medium";
      }
    ];

    extraConfig = ''
      set list
      set listchars=tab:╰─,trail:·

      set mouse=""
      let mapleader=","

      set number
      let &colorcolumn="80,120"
    '';

  };

}
