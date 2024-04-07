{
  description = "NixOS Configuration for the Open Computing Facility <https://ocf.berkeley.edu>";

  inputs = {
    # Global NixOS system version
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";

    # Separate nixpkgs pin for Kubernetes (we don't want to accidentally update that)
    kubePin.url = "github:nixos/nixpkgs/fd281bd6b7d3e32ddfa399853946f782553163b5";

    # Some helper methods...
    flakeUtils.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.4.0";
  };

  outputs = { self, flakeUtils, ... }@inputs:
    flakeUtils.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];
      channelsConfig.allowUnfree = true;

      # Packages to take from kubePin...
      channels.nixpkgs.overlaysBuilder = channels: [
        (final: prev: { inherit (channels.kubePin) cri-o; })
        (final: prev: { inherit (channels.kubePin) kubernetes; })
      ];

      # Things to pass into every host configuration...
      hostDefaults.modules = [ ./profiles/base.nix ./profiles/kubernetes ./profiles/kubernetes/ocfcrio.nix ];

      # NixOS will compare the currently set hostname to hosts.* and apply the one that matches.
      hosts.adenine.modules = [ ./hosts/adenine.nix ]; # nucleus A
      hosts.guanine.modules = [ ./hosts/guanine.nix ]; # nucleus B
      hosts.cytosine.modules = [ ./hosts/cytosine.nix ]; # nucleus C
      hosts.thymine.modules = [ ./hosts/thymine.nix ]; # nucleus D

      outputsBuilder = channels: {
        formatter = channels.nixpkgs.nixpkgs-fmt;
      };
    };
}

