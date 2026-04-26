{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.languages;
in
{
  options.orbal.languages = {
    node.enable = mkEnableOption "JavaScript toolchain (bun, bunx)";
    typescript.enable = mkEnableOption "TypeScript toolchain (tsc, typescript-language-server)";
    go.enable = mkEnableOption "Go toolchain (go, gopls)";
    rust.enable = mkEnableOption "Rust toolchain (rustc, cargo, rust-analyzer)";
    python.enable = mkEnableOption "Python toolchain (python3, virtualenv)";
  };

  config = {
    environment.systemPackages = with pkgs;
      optionals cfg.node.enable [ bun ]
      ++ optionals cfg.typescript.enable [ typescript typescript-language-server ]
      ++ optionals cfg.go.enable [ go gopls ]
      ++ optionals cfg.rust.enable [ rustc cargo rust-analyzer ]
      ++ optionals cfg.python.enable [ python3 python3Packages.virtualenv ];
  };
}
