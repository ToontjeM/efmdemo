# EDB Failover Manager

In this demo you will be able to show the main functtionality of EDB Failover Manager using a Virtual IP address. 
Additionally you will be able to show basic Barman functtionality and run a demo of Transparent data encryption.

This demo is based on pre-provisioned virtual machines, all software is deployed using [EDB Trusted Postgres Architect (TPA)](https://www.enterprisedb.com/docs/tpa/latest/).

## Demo prep
The demo is based on three nodes, a primary Postgres node, a standby and a witness. All nodes are running the EFM agent and the witness is also running `barman` for continuous backup.

| Name VM | IP | Function |
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
- Explain what is deployed using the TPA template.

### EFM failover demo
Open three terminal panes, one for the primary, one for the witness and one to a local machine which has the Postgres Client Tools installed.

**Witness**

- Run a continous cluster status using `watch sudo /usr/edb/efm-4.9/bin/efm cluster-status efmcluster`.

**Client**

- Connect to the VIP address using `psql -h 192.168.0.169 -p 5444 -U enterprisedb edb`
- Create a test database and insert random records in it.
  ```
  enterprisedb@primary:~ $ psql -h 192.168.0.169 -p 5444 -U enterprisedb edb
  psql (16.8.0)                                                                                                                               
  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)                                                        
  Type "help" for help.                                                                                                                       
  
  edb=# CREATE TABLE test (id SERIAL PRIMARY KEY, random_text TEXT);                                                                                                                                    
  CREATE TABLE                                                                                                                                
  edb=# INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);
  INSERT 0 100
  edb=# SELECT COUNT(*) FROM test;
  count                                                                                                                                      
  -------                                                                                                                                     
    100                                                                                                                                      
  (1 row)                                                                                                                                     
                                                                                                                                          
  edb=#
  ```

Show LSN updating on both nodes indicating that replication is working.

**Primary**
- Become user `enterprisedb` using `sudo su - enterprisedb`.
- Stop postgres using `pg_ctl stop -D ${PGDATA}`

Notice that EFM will detect Postgres not available and will performa a failover.

```
Every 2.0s: sudo /usr/edb/efm-4.9/bin/efm cluster-status efmcluster                                         backup: Tue Feb 25 10:54:35 2025

Cluster Status: efmcluster

        Agent Type  Address              DB       VIP
        ----------------------------------------------------------------
        Idle        192.168.0.170        UNKNOWN  192.168.0.169
        Primary     192.168.0.171        UP       192.168.0.169*
        Witness     192.168.0.172        N/A      192.168.0.169

Allowed node host list:
        192.168.0.171 192.168.0.170 192.168.0.172

Membership coordinator: 192.168.0.171

Standby priority host list:
        (List is empty.)

Promote Status:

        DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------------------
        Primary     192.168.0.171                           0/37013DB8

        No standby databases were found.

Idle Node Status (idle nodes ignored in WAL LSN comparisons):

        Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------
        192.168.0.170        UNKNOWN            UNKNOWN            Connection to 192.168.0.170:5444 refused. Check that the hostname and por
t are correct and that the postmaster is accepting TCP/IP connections.
```

**Client**

- Perform the same query as before (arrow up) to reconnect to the database.
  ```
  edb=# select count(*) from test;
  FATAL:  terminating connection due to administrator command
  SSL connection has been closed unexpectedly
  The connection to the server was lost. Attempting reset: Succeeded.
  psql (17.2 (Homebrew), server 16.8.0)
  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off, ALPN: none)
  edb=# select count(*) from test;
   count 
  -------
      10
  (1 row)
  ```

- Reinsert a couple of new rows using the INSERT statement as before and perform the COUNT again.
  ```
  edb=# INSERT INTO test (random_text)
  SELECT md5(random()::text)
  FROM generate_series(1, 100); -- Change 10 to any number of rows you want
  INSERT 0 100
  edb=# select count(*) from test;
   count 
  -------
     110
  (1 row)
  ```

You can see that the cluster continues to be running with a new primary.
