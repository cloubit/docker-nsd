# Dockerfile for NSD DNS Server Docker Image

[NSD](https://nlnetlabs.nl/projects/nsd/about/)⁠ is an open source stable, high-performance and secure DNS-Server, developed by [NLnet Labs](https://www.nlnetlabs.nl/)

## Image details

-  NSD 4.12.0
-  Openssl 3.5.0

## Create Docker image
If you have Git installed, Clone the NSD repository to your local host with
´´´sh
git clone https://github.com/cloubit/docker-nsd.git
´´´
or download the last repository.
If you have docker installed, you can create your own Docker Image about:
´´´sh
docker build -t nsd:4.12.0 .
´´´

## Run the NSD Docker Container
Start the Docker container with a volume and copy your configuration file (nsd.conf) in the folder.
Create a folder "zones" and copy your zone Files in the zones folder. 
You find example config and zone files on our [GitHub](https://github.com/cloubit/nsd-docker) repository

Use the command like this:
```sh 
docker run --name nsd -d -p 53:53/udp -p 53:53/tcp --volume </local/path/to/your/config:/opt/nsd/etc/nsd \
--restart=always nsd:4.12.0
```

## Docker Hub
[Link to the NSD-Server Docker image](https://hub.docker.com/r/cloubit/nsd)
