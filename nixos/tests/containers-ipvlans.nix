# Test for NixOS' container support.

let
  # containers IP on VLAN 1
  containerIp1 = "192.168.1.253";
  containerIp2 = "192.168.1.254";
in

import ./make-test.nix ({ pkgs, ...} : {
  name = "containers-ipvlans";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ montag451 ];
  };

  nodes = {

    machine1 =
      { lib, ... }:
      {
        virtualisation.memorySize = 256;
        virtualisation.vlans = [ 1 ];

        # To be able to ping containers from the host, it is necessary
        # to create an ipvlan on the host on the VLAN 1 network.
        networking.ipvlans.iv-eth1-host = {
          interface = "eth1";
          mode = "L2";
          flags = "bridge";
        };
        networking.interfaces.eth1.ipv4.addresses = lib.mkForce [];
        networking.interfaces.iv-eth1-host = {
          ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
        };

        containers.test1 = {
          autoStart = true;
          ipvlans = [ "eth1" ];

          config = {
            networking.interfaces.iv-eth1 = {
              ipv4.addresses = [ { address = containerIp1; prefixLength = 24; } ];
            };
          };
        };

        containers.test2 = {
          autoStart = true;
          ipvlans = [ "eth1" ];

          config = {
            networking.interfaces.iv-eth1 = {
              ipv4.addresses = [ { address = containerIp2; prefixLength = 24; } ];
            };
          };
        };
      };

    machine2 =
      { ... }:
      {
        virtualisation.memorySize = 256;
        virtualisation.vlans = [ 1 ];
      };

  };

  testScript = ''
    startAll;
    $machine1->waitForUnit("default.target");
    $machine2->waitForUnit("default.target");

    # Ping between containers to check that ipvlans are created in L2 bridge mode
    $machine1->succeed("nixos-container run test1 -- ping -n -c 1 ${containerIp2}");

    # Ping containers from the host (machine1)
    $machine1->succeed("ping -n -c 1 ${containerIp1}");
    $machine1->succeed("ping -n -c 1 ${containerIp2}");

    # Ping containers from the second machine to check that containers are reachable from the outside
    $machine2->succeed("ping -n -c 1 ${containerIp1}");
    $machine2->succeed("ping -n -c 1 ${containerIp2}");
  '';
})
