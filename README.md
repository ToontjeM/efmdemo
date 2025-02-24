# EDB Failover Manager

In this demo you will be able to show the main functtionality of EDB Failover Manager using a Virtual IP address. 
Additionally you will be able to show basic Barman functtionality and run a demo of Transparent data encryption.

This demo is based on pre-provisioned virtual machines, all software is deployed using [EDB Trusted Postgres Architect (TPA)](https://www.enterprisedb.com/docs/tpa/latest/).

## Demo prep
The demo is based on three nodes, a primary Postgres node, a standby and a witness. All nodes are running the EFM agent and the witness is also running `barman` for continuous backup.

 Name VM | IP | Function |
| --- | --- | --- |
| efmprimary | 192.168.0.170 | Postgres primary |
| efmstandby | 192.168.0.171 | Postgres standby |
| efmwitness | 192.168.0.172 | EFM witness and barman server |

The software configuration is based on the following TPA template:
```
---
architecture: M1
cluster_name: efmcluster
cluster_tags:
  Owner: ton.machielsen@enterprisedb.com    // Replace this with your own email address

keyring_backend: legacy
vault_name: 61bc1e2a-e818-4382-b146-72c188b1bacf
ssh_key_file: ~/.ssh/id_rsa                 // Replace this with your own SSH keys

cluster_vars:
  apt_repository_list: []
  edb_repositories:
  - enterprise
  failover_manager: efm
  postgres_flavour: epas                    // We will be usiing EDB Postgres Advanced Server for TDE functionality
  postgres_version: '16'                    // Version 16
  preferred_python_version: python3
  use_volatile_subscriptions: true
  yum_repository_list:
  - EPEL
  generate_password: false

  efm_conf_settings:
    local.timeout: 10
    local.period: 5
    application.name: app
    ping.server.ip: 127.0.0.1
    virtual.ip: 192.168.0.169               // This will be the EFM Virtual IP
    virtual.ip.prefix: 24
    virtual.ip.interface: ens18             // Replace this with the correct NIC in your environment
    ping.server.command: '/bin/ping -q -c3 -w5'

  postgres_conf_settings:
    wal_level: replica
    max_wal_senders: 10
    wal_keep_size: 500
    max_replication_slots: 10

locations:
- Name: main

instance_defaults:
  platform: bare
  vars:
    ansible_user: ton                       // Replace this with the user who will be running TPA
    manage_ssh_hostkeys: no

instances:
- Name: primary
  backup: backup
  location: main
  node: 1
  ip_address: 192.168.0.170                 // Replace this with the IP of the primary.
  role:
  - primary
- Name: standby
  location: main
  node: 2
  ip_address: 192.168.0.171                 // Replace this with the IP of the standby.
  role:
  - replica
  upstream: primary
- Name: backup
  location: main
  node: 3
  ip_address: 192.168.0.172                 // Replace this with the IP of the witness.
  role:
  - witness
  - barman
  - log-server
  upstream: primary
```

### Provisioning servers
- Provision the three VM's any way you like (vagrant, proxmox, EC2, etc.)
- Install TPA according to https://www.enterprisedb.com/docs/tpa/latest/INSTALL/
- Make sure you follow all prerequisites for bare-metal deployments documented here: https://www.enterprisedb.com/docs/tpa/latest/platform-bare/

### Deploying software
- Make sure you have your $EDB_SUBSCRIPTION_TOKEN properly configured.
- Create a dummy cluster configuration using `tpaexec configure efmcluster --architecture M1 --postgresql 14 --failover-manager repmgr`. This dummy configuration will be overwritten by the template mentioned above.
- Copy `tpaconfig.efmcluster` to the cluster directory created by the `tpaexec configure` command and call the file `config.yml`.
- Provision the cluster using `tpaexec provision efmcluster`.
- Deploy the cluster using `tpaexec deploy efmcluster`.

You should now have a working EFM software installation. Check the correcct working by running `tpaexec test efmcluster`.

TPA will create random complex passwords. These passwords can be retrieved using `tpaexec show-password <cluster> <user>`.

Example:
```
√  main +39 -17 ~/efmdemo tpaexec show-password efmcluster enterprisedb
WGm^wc&Ed%ucPzBGPxLVBwuJwjkd0ek_
√  main +39 -17 ~/efmdemo tpaexec show-password efmcluster efm
w%QHzBxjRuksKbpahMF6K200%dTlEbzN
√  main +39 -17 ~/efmdemo tpaexec show-password efmcluster barman
uBSsR8kwbu76tD5*kUBd&r55UUMIy7g&
√  main +39 -17 ~/efmdemo 
```

## Demo flow.
### EFM failover demo
Open three terminal panes, one for each node and follow this flow:

| --- | --- | --- |
| Primary | Standby | Witness |
| sudo su - efm | | sudo su - enterprisedb |

### Transparent Data encryption

### Barman

