{
  description = "blink-cmp-ghostty — Ghostty configuration completion source for blink.cmp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forEachSystem (
        pkgs:
        let
          luaEnv = pkgs.luajit.withPackages (
            ps: with ps; [
              busted
              nlua
            ]
          );
          commonPackages = [
            luaEnv
            pkgs.biome
            pkgs.just
            pkgs.lua-language-server
            pkgs.selene
            pkgs.stylua
            pkgs.vimdoc-language-server
          ];
        in
        {
          default = pkgs.mkShell {
            packages = commonPackages;
          };
          ci = pkgs.mkShell {
            packages = commonPackages ++ [ pkgs.neovim ];
          };
        }
      );
    };
}
