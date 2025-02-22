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
* The Openstack Controllers run on Ubuntu VMs in Proxmox
* The Openstack Compute Nodes are commodity compute hardware
  * These nodes have a default Ubuntu 24.04 Server installation
  * With following NIC setup:
    * 1GB - Management
    * 2x 10GB - One for Self-service traffic, One for Provider Traffic
    * 50GB - Storage
* Network Ranges are as follows:
  * Management: 192.168.23.0/24
    * Gateway: 192.168.23.254
  * Self Service: 192.168.72.0/24
    * Gateway: N/A
  * Provider: 192.168.52.0/24
    * Start: 192.168.52.50
    * End: 192.168.52.150
    * Gateway: 192.168.52.254
  * Storage: 192.168.27.0/24
    * Gateway: N/A

## Roles

* Base Controller
  * Base configuration for all Openstack Controller Nodes
    * Excluding SQL & Message Queue
* Base Compute
  * Base configuration for all Openstack Compute Nodes
* Base Shares
  * Base configuration for all Openstack Nodes
* Keystone
  * Install & Configure Keystore
* Cinder Controller
  * Install & Configure Cinder Controller
* Cinder Storage
  * Install & Configure Cinder Storage
* Glance
  * Install & Configure Glance
* Placement
  * Install & Configure Placement
* Nova Controller
  * Install & Configure Nova Controller
* Nova Compute
  * Install & Configure Nova Compute
* Neutron Controller
  * Install & Configure Neutron Controller with OVN
* Neutron Compute
  * Install & Configure Neutron Compute with OVN
* Octavia Controller
  * Install & Configure Octavia Controller with OVN
* Dashboard
  * Install & Configure Dashboard

## Run

```bash
ansible-playbook -i hosts site.yaml -v --diff
```
