# ansible_openstack
Ansible to Manage Openstack in my Home Lab

## Assumptions

This ansible playbook is specific to my Home Lab and makes the following assumptions:

* Compute Storage is provided via a TrueNAS Server over NFS
  * NFS mounts are configured with sync=always plus some other flags for performance and stability reasons
  * iSCSI is an option but there is storage and performance considerations with ZFS
    * I haven't actually tested this, just based off of posts on the TrueNAS forums.
    * Also the "50%" free space guidelines and whatnot are a bit annoying
    * NFS is also easier to deubg and troubleshoot since it can easily be mounted anywhere
  * This node has dual 10Gb NICs configured in a a LACP bond
    * Due to using NFS this was chosen as NFS does not support multipath networking
      * NFS v4.1 supports multipath but it's not wide spread enough
* The Openstack Controllers run on Raspberry Pis
  * The Pis are imaged using the openstack-node image found here https://github.com/rmb938/rpi-images
    * The image is based off of Ubuntu Server https://ubuntu.com/raspberry-pi
* The Openstack Compute Nodes are commodity compute hardware
  * These nodes have a default Ubuntu 22.04 Server installation
  * These nodes are "upgraded" with a Chelsio T520-CR NIC configured in a LACP bond
* Due to the limitations of a homelab I have chosen to use `veth` devices to seperate traffic instead of physical NICs. All networking will be setup in the following way:
  * If a host has multiple nics they will be bonded under `bond0` configured with LACP
  * The `bond0` (or single nic) will then be placed in a bridge `br0`
  * Two `veths` will be created and placed under `br0`
    * `veth0-mgmt` is the Openstack Management Interface
    * `veth1-provider` is the Openstack Provider Interface
    * These `veths` will be on the same physical network with no VLAN seperation, this means the management and provider networks will be the same CIDR ranges. 
      * This is a Home Lab not an enterprise, it is ok to share these networks in a low risk setting like this.
  * Example:
    ```
    br0
    ├── veth0
    │   └── veth0-mgmt
    │       ├── Address: 192.168.23.x/24
    │       └── Gateway: 192.168.23.254
    ├── veth1
    │   └── veth1-provider
    │       └── Unnumbered
    └── bond0
        ├── eth0
        └── eth1
    ```
* Network Ranges are as follows:
  * Storage: 192.168.23.40 - 192.168.23.49
  * Raspberry Pis: 192.168.23.70 - 192.168.23.79
  * Compute Nodes: 192.168.23.50 - 192.168.23.59
  * Provider Network: 192.168.23.100 - 192.168.23.200
    * Openstack will be configured with **no** DHCP server as we don't want it conflicting with the management LAN
* All hosts have Tailscale installed and are defined in the `hosts` file with their Tailscale hostname i.e `pi1.tailnet-047c.ts.net`
  * TODO: All services have TLS configured via Tailscale certificates
  * TODO: All services are configured to only be accessable via the Tailscale network and using Tailscale ACLs for access control
    * All Openstack Tailscale nodes have the `servers` and `openstackNode` tags.
    ```json
    {
      "tagOwners": {
        "tag:servers":       ["autogroup:members"],
        "tag:openstackNode": ["autogroup:members"],
      },

      // Access control lists.
      "acls": [
        { // anything can ipv4 ping anything
          "action": "accept",
          "proto":  "1", // icmp ipv4
          "src":    ["*"],
          "dst":    ["*:*"],
        },
        { // anything can ipv6 ping anything
          "action": "accept",
          "proto":  "58", // icmp ipv6
          "src":    ["*"],
          "dst":    ["*:*"],
        },
        // ssh into servers
        {
          "action": "accept",
          "proto":  "TCP",
          "src": [
            "autogroup:members",
          ],
          "dst": ["tag:servers:22"],
        },
        // openstack things can talk to other openstack things
        { // Openstack APIs
          "action": "accept",
          "src": [
            "tag:openstackNode", // openstack nodes need to talk to the openstack api
            "tag:servers", // servers need to talk to the openstack api
            "autogroup:members", // members need to talk to openstack api
          ],
          "dst": [
            "tag:openstackNode:80",
            "tag:openstackNode:443",
            "tag:openstackNode:5000", // keystone
            "tag:openstackNode:8776", // cinder
            "tag:openstackNode:9292", // glance
            "tag:openstackNode:8778", // placement
            "tag:openstackNode:8774", // nova
            "tag:openstackNode:8775", // nova metadata
            "tag:openstackNode:9696", // neutron
            "tag:openstackNode:9876", // actavia
          ],
        },
        {// vnc console
          "action": "accept",
          "src": [
            "autogroup:members", // members need to talk to openstack api
          ],
          "dst": [
            "tag:openstackNode:6080", // vnc console
          ],
        },
        { // OVSDB
          "action": "accept",
          "src":    ["tag:openstackNode"],
          "dst": [
            "tag:openstackNode:6641", // nothd
            "tag:openstackNode:6642", // southd
          ],
        },
        { // Memcached
          "action": "accept",
          "src":    ["tag:openstackNode"],
          "dst":    ["tag:openstackNode:11211"],
        },
        { // MySQL
          "action": "accept",
          "src":    ["tag:openstackNode"],
          "dst":    ["tag:openstackNode:3306"],
        },
        { // RabbitMQ
          "action": "accept",
          "src":    ["tag:openstackNode"],
          "dst":    ["tag:openstackNode:5672"],
        },
      ],
      "ssh": [
        // Allow members to ssh into servers, with auth checking
        {
          "action": "check",
          "src":    ["autogroup:members"],
          "dst":    ["tag:servers"],
          "users":  ["autogroup:nonroot"],
        },
      ],
    }
    ```

## Requirements

* Tailscale
  * Ubuntu - X86
    ```bash
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
    apt-get update
    apt-get install tailscale
    systemctl enable --now tailscaled
    tailscale up --ssh
    ```
  * Ubuntu - RPI
    ```bash
    systemctl enable --now tailscaled
    tailscale up --ssh
    ```
* Ansible User created and setup with sudo
  ```bash
  useradd ansible
  mkdir /home/ansible
  chown ansible:ansible /home/ansible/
  echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible
  ```
