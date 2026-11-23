# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which git commit of the nixpkgs channel to use
  channel = "stable-23.11"; # or stable-24.05

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.nodePackages.firebase-tools
    pkgs.jdk17
    pkgs.unzip
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart"
    ];

    # Enable previews and configure them
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["flutter" "run" "-d" "web-server" "--web-port" "$PORT"];
          manager = "web";
        };
        android = {
          command = ["flutter" "run" "-d" "android" "-v"];
          manager = "android";
        };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        # Example: install JS dependencies from NPM
        # npm-install = "npm install";
      };
      # Runs when the workspace is (re)started
      onStart = {
        # Example: start a developer server to run your app
        # dev-server = "npm run dev";
      };
    };
  };
}
