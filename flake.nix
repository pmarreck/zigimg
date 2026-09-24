{
  description = "zigimg — pure-Zig image I/O library (Zig 0.16)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    test-suite = {
      url = "github:zigimg/test-suite";
      flake = false;
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, test-suite }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zig = zig-overlay.packages.${system}."0.16.0";
      in {
        # The default build installs the library's test binary.
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "zigimg";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ zig ];
          dontConfigure = true;
          buildPhase = ''
            export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
            mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
            zig build -Doptimize=ReleaseFast --prefix $out
          '';
          installPhase = "true";
        };

        checks.build = self.packages.${system}.default;
        checks.test = self.packages.${system}.default.overrideAttrs {
          pname = "zigimg-tests";
          buildPhase = ''
            runHook preBuild
            export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
            mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
            ln -s ${test-suite} ../test-suite
            zig build test -Doptimize=ReleaseSafe --summary all --prefix $out
            runHook postBuild
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ zig pkgs.git ];
        };
      });
}
