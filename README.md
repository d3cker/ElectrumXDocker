# ElectrumX Docker
Dockerfile for ElectrumX server. This is developed for 
*spesmilo/electrumx* fork which supports Bitcoin network. 
Please visit: https://github.com/spesmilo/electrumx for more information.

## Cause and purpose

Idea behind this container popped up when there was a need to run ElectrumX
on remote Raspberry PI. Unfortunately it had (and still has) Python 3.7 
installed with a lot of extra packages. One way to go was to upgrade Python.
It turns out it was not that straight forward because there were some 
applications already running. Making everything to work as expected after 
the upgrade could be time consuming. Moving to Docker was a next thought. It 
was much faster to develop containerized solution than upgrading existing OS. 
This contianer was build and run with success on: 
- Raspberry Pi 4 32bit Raspbian OS,Docker version 20.10.12
- Raspberry Pi Compute Module 4 64bit Raspbian OS,Docker version 20.10.12
- x86_64 AMD powered machine running Ubuntu 20.04.2 LTS,Docker version 20.10.12
- x86_64 Intel powered machine running Windows 10,Docker version 20.10.12

## Build prerequisites 
 
Machine with a Docker. 

## Container structure

- Base image is Python 3.8 to meet minimum requirements
- Source code is stored in /electrumx folder.
- Commit `c5d1e802e7a7e98db36fbad79954b3a46b9e03f3` was chosen to be used.
- _electrumx_ user and group are created with uid:gid = 1000:1000.
- _electrumx_'s home folder set to `/electrumx` and its permisions are 
  read-only.
- root priviledges are dropped and `electrumx_server` is executed as electrumx
  user.

## Running the container

### Prerequisites

The following example will be dedicated for Linux systems and Bitcoin network.

1) Bitcoin node

It's a little bit out of the scope but still a very usefull tip. 
Before starting ElectrumX server it's required to run some coin node.
Node should be fully synchronized with the blockchain. Here is the important 
part. **Before starting the node, set up `txindex=1` in configuration file!**.
During the development this part was missed which resulted in reindexing the 
whole blockchain. Long story short, it took more or less the same amount of 
time to reindex as syncing from the scratch. So, to save some time, attention
should be paid to this configuration variable. Also one should keep in mind 
that current Bitcoin blockchain weights ~500GB.

2) ElectrumX host machine

ElectrumX in Docker requires some place to store its database. For this 
purpose a volume should me mounted to the container. Since the container
runs as user with uid 1000 and gid 1000, the same ownership should be set 
on a folder. For example:

```
$ sudo mkdir /electrumdb
$ sudo chown 1000:1000 /electrumdb
```

Of course Docker daemon should be up and running and user should have 
permissions to use it. 

### Buildint the image

Clone the repository and execute `docker build` command:

```
$ git clone https://github.com/d3cker/ElectrumXDocker.git
$ cd ElectrumXDocker
$ docker build . -t electrumx

```

### Starting the contianer

For ElectrumX configuration details, please visit its Github repository:
https://github.com/spesmilo/electrumx/blob/master/docs/
In this example ElectrumX will:
- use `/electrumdb` mounted from host machine
- connect to the Bitcoin RPC node runing on 192.168.0.69
- expose port 50001 for clear text TCP and 8000 for websockets
- run in a background as a deamon

```
$ docker run -d \
-v /electrumdb:/electrumdb -p 50001:50001 -p 8000:8000 \
-e "DB_DIRECTORY=/electrum" \
-e "DAEMON_URL=http://rpcuser:rpcpassword@192.168.0.69:8332/" \
-e "COIN=Bitcoin" \
-e "SERVICES=tcp://:50001,ws://:8000,rpc://" \
electrumx
```
Once executed, it should take some time to sync with Bitcoin node. On old
AMD FX(tm)-8120 Eight-Core Processor with 7200RPM HDD it took ~4 days. Be 
patient and monitor the progress.

### Testing

Two TCP ports should be opened by ElectrumX server: 50001 and 8000. It's worth
to mention that container will expose those ports from the very beginning
but they **won't be useful until synchronisation is finished**. To verify that
ElectrumX is working, Electrum client must be configured to connect to:
```
address_of_electrumx_host:50001:t
```
Please, note `:t` at the end of the address. This will inform Electrum client 
to use plain text connection. For SSL please follow instructions from 
*[HOWTO](https://github.com/spesmilo/electrumx/blob/master/docs/HOWTO.rst)*.


### Known issues

It was observed that ElectrumX failed to flush synchronization data when 
container was stopped with either `docker stop` or `docker kill`. Despite
having clear message that flush was completed, synchrozation was pushed back
during next start. The only way to shutdown ElectrumX properly is to `docker
attach` and hit Ctrl+C. One should be careful during first initialization phase
because it is possible to lose all the progress on unattended shutdown.
This issue is to be investigated in the future (hopefully).

