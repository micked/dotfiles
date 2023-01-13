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
      };
    };
    languages = [
      {
        name = "rust";
        language-server = {command = "${pkgs.rust-analyzer}/bin/rust-analyzer";};
      }
      {
        name = "python";
        language-server = {command = "${pkgs.python310Packages.python-lsp-server}/bin/pylsp";};
        formatter = {
          command = "${pkgs.black}/bin/black";
          args = ["-q" "-"];
        };
      }
      {
        name = "nix";
        language-server = {command = "${pkgs.nil}/bin/nil";};
        formatter = {
          command = "${pkgs.alejandra}/bin/alejandra";
          args = ["--quiet"];
        };
      }
    ];
  };
}
