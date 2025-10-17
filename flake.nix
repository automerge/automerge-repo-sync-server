{
  description = "Automerge repo sync server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:

  let
    nixosModule = { config, lib, pkgs, ... }: {

      options.services.automerge-repo-sync-server = {
        enable = lib.mkEnableOption "Automerge repo sync server";

        port = lib.mkOption {
          type = lib.types.port;
          default = 3030;
          description = "Port on which thesync server's websockets server will listen.";
        };

        dataDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/automerge/data";
          description = ''
            Directory where Automerge repo sync server stores persistent data.
            The directory will be created automatically and made writable
            by the service user.
          '';
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          description = "Extra environment variables for the Automerge repo sync server.";
        };
      };

      config = lib.mkIf config.services.automerge-repo-sync-server.enable {
        # define user and group
        users.users.automerge = {
          isSystemUser = true;
          group = "automerge";
          home = "/var/lib/automerge";
          createHome = true;
        };
        users.groups.automerge = {};
        # define service
        systemd.services.automerge-repo-sync-server = {
          description = "Automerge repo sync server";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            StateDirectory = "automerge";
            RuntimeDirectory = "automerge";
            WorkingDirectory = "/var/lib/automerge";

            # extra quotes necessary to escape the at-symbol (@) for systemd
            ExecStart = ''"${self.packages.${pkgs.system}.default}/bin/@automerge/automerge-repo-sync-server"'';
            Restart = "always";
            User = "automerge";
            Group = "automerge";

            Environment = lib.flatten ([
              "PORT=${toString config.services.automerge-repo-sync-server.port}"
              "DATA_DIR=${config.services.automerge-repo-sync-server.dataDir}"
              "NODE_ENV=production"
            ] ++ lib.mapAttrsToList (n: v: "${n}=${v}") config.services.automerge-repo-sync-server.environment);
          };
        };
      };

    };
  in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        npmDepsHash = import ./npm-deps-hash.nix;
      in {
        packages.default = pkgs.buildNpmPackage {
          pname = "@automerge/automerge-repo-sync-server";
          version = "0.3.0";
          src = ./.;
          # set in ./npm-deps-hash.nix
          inherit npmDepsHash;

          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/node/build-npm-package/default.nix
          dontNpmBuild = true;
          # https://docs.npmjs.com/cli/v10/commands/npm-ci?v=true#omit
          npmInstallFlags = [ "--omit=dev" ];
        };
      }
    ) // {
      # automerge nixOS service
      nixosModules.default = nixosModule;
    };
}
