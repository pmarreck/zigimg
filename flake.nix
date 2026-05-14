{
  description = "zigimg — pure-Zig image I/O library (Zig 0.16)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zig = zig-overlay.packages.${system}."0.16.0";
      in {
        # zigimg is a pure-Zig library — `zig build` produces a test binary
        # plus zig-out/lib (depending on options). We let build.zig install
        # whatever it wants into $out and copy the result.
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "zigimg";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ zig ];
          dontConfigure = true;
          buildPhase = ''
            export HOME=$TMPDIR
            export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
            mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
            zig build -Doptimize=ReleaseFast --prefix $out
          '';
          installPhase = "true";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ zig pkgs.git ];
        };
      });
}
