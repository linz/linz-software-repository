let
  pkgs =
    import
      (
        fetchTarball (
          builtins.fromJSON (
            builtins.readFile ./nixpkgs.json
          )
        )
      )
      { };
in
pkgs.mkShell {
  packages = [
    pkgs.cacert
    pkgs.cargo
    pkgs.docker
    pkgs.gitFull
    pkgs.gnumake
    pkgs.nodejs
    pkgs.pre-commit
    pkgs.shfmt
    pkgs.which
  ];
}
