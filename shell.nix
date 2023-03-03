let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
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
