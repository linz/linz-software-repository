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
    pkgs.docker
    pkgs.gitFull
    pkgs.hadolint
    pkgs.nixpkgs-fmt
    pkgs.nodePackages.prettier
    pkgs.pre-commit
    pkgs.shellcheck
    pkgs.shfmt
  ];
}
