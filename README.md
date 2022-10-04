# EDB Failover Manager - Demo
This project contains the sources for the automatic installation of the EFM environment as well as the description of the EFM demo.

## How to install the demo environment

The EFM environment will be installed in AWS (Cloud) using the tpaexec tool.

**Important**: This EFM demo works with TPAEXEC version 23.6 and higher. Please make sure that you have installed the version >=23.6.

## Deployment preparation

1. Create the file contained the credentials for the access the EDB YUM Repository
   
   **Important**: Replace EDB-REPO-Username:EDB-REPO-Password with your current username/password

```
echo "EDB-REPO-Username:EDB-REPO-Password" > ~/.edbrepocred
export EDB_REPO_CREDENTIALS_FILE="$HOME/.edbrepocred"
```

2. Enable any 2ndQuadrant repositories and set the variable

```
export TPA_2Q_SUBSCRIPTION_TOKEN=<your token>
```

3. Obtain the AWS Credentials to accessing the AWS and to create the EFM VMs, then export following variables

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

4. Include the binary tpaexec in the PATH Variable

   For example:
   
 ```
export PATH=<Path to the tpaexec binary>:${PATH}
``` 

5. Download this repository

   In my environment I will download the repository to the directory /git/projects

``` 
cd /git/projects
git clone git@github.com:EnterpriseDB/bn-efmdemo-2022.git
cd /git/projects/bn-efmdemo-2022
``` 

5. Edit the file config.yml and replace owner with your Name or E-Mail Address

```
cluster_tags:
  Owner: borys.neselovskyi@enterprisedb.com
```

Now you ready to install and configure the EFM Environment in the AWS

## Deployment

Navigate to the directory with sources, in my example /git/projects/bn-efmdemo-2022.

Run ```tpaexec relink``` to rebuild tpaexec contents

```
cd /git/projects/bn-efmdemo-2022
tpaexec relink .
```

Now run following commands to setup the EFM environment in AWS:

```
tpaexec provision .
tpaexec deploy .
```

Please ignore the following error message:

```
TASK [pem/agent/config/final : Register PEM backend database server for monitoring and configuration] ******************

fatal: [pemserver -> {{ pem_server }}]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'str object' has no 

attribute 'node_dsn'\n\nThe error appears to be in '/opt/EDB/TPA/roles/pem/agent/config/final/tasks/register-pem-server.yml': line 19, column 3, but 

may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Register PEM backend database 

server for monitoring and configuration\n  ^ here\n"}
```

## Test the deployment

Navigate to your working directory (in my case: /git/projects/bn-efmdemo-2022) and test the connection to vms pg1, pg2 and pg3:

```
cd /git/projects/bn-efmdemo-2022
ssh -F ssh_config pg1
ssh -F ssh_config pg2
ssh -F ssh_config pg3
```

## Setup the Demo

Run the script ```demo_prep.sh``` and setuo the EFM demo. 

The script creates the table EMP, create some replication slots and changes some efm settings

```
cd /git/projects/bn-efmdemo-2022
chmod 744 demo_prep.sh
chmod -R 744 scripts
./demo_prep.sh
```

Now you are able to run the demo

## Run Demo

see documentation [Demo Script](https://github.com/EnterpriseDB/bn-efmdemo-2022/blob/ee251ab4996f49e0a2b33900bdcfad92858fc30b/EFM_Demo_AWS_Script.md)

## Remove the EFM Environment

To delete the created EFM VMs please run the following command:

```
cd /git/projects/bn-efmdemo-2022
tpaexec deprovision .
```
