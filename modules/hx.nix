{
  config,
  pkgs,
  libs,
  ...
}: {
  programs.helix = {
    enable = true;
    settings = {
      theme = "nord";
      editor = {
        rulers = [80 120];
        cursor-shape.insert = "bar";
        bufferline = "always";
      };
    };
    languages = {
      language-server = {
        rust-analyzer = {command = "${pkgs.rust-analyzer}/bin/rust-analyzer";};
        pylsp = {command = "${pkgs.python3Packages.python-lsp-server}/bin/pylsp";};
        nil = {command = "${pkgs.nil}/bin/nil";};
      };
      language = [
        {
          name = "rust";
          language-servers = ["rust-analyzer"];
        }
        {
          name = "python";
          language-servers = ["pylsp"];
          formatter = {
            command = "${pkgs.black}/bin/black";
            args = ["-q" "-"];
          };
        }
        {
          name = "nix";
          language-servers = ["nil"];
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
            args = ["--quiet"];
          };
        }
      ];
    };
  };
}
