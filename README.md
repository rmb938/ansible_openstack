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
  * This ansible will uninstall NetworkManager and install and configure systemd-networkd
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
    * Openstack will be configured with **no** DHCP server, instances will have their network configured via ConfigDrive https://docs.openstack.org/nova/latest/user/metadata.html

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
