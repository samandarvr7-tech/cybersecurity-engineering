## Why NIDS First?
First of all, we have to build our environment where we can simulate real attacks so we can start our Detection Engineering. For the beginning, I decided to start with learning NIDS because it is the easiest tool and requires the least amount of resources and effort. Moreover, everything starts exactly in the network; to reach the target, the attack should come over the network. It is the first wall of defense, and it is another reason why we should learn the network first and familiarize ourselves with packets and logs before diving deeper.

## Why this structure
Since my own laptop is weak and doesn't have enough resources, I was confused at first. But thanks to the GitHub Student Pack, I had free credits on Digital Ocean, so I created a droplet with 1CPU, 2GB RAM, and 50GB Disk. The idea is simple: DVWA will be just like a real web app, and Suricata will be inspecting all incoming traffic just like in reality. We will attack it from our own PC/Laptop over the network, just like real attacks happen.
## Resources & Tools
*   `Ubuntu` Server with `1CPU` `2GB RAM`
*   Laptop/PC
*   `DVWA`
*   `Suricata`

## Lets build

### 1. System Preparation
* Update the host system packages to ensure stability
```
sudo apt update
sudo apt upgrade
```
* Then we need docker to run DVWA
```
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
* Check if docker is installed successfully, you should be able to see their versions in the output.
```
sudo docker version
sudo docker compose version
```
```
# Check status aswell
sudo systemctl status docker
# In case docker didnt started, start it manually
sudo systemctl start docker
```
### 2. DVWA Installation
```
git clone https://github.com/digininja/DVWA.git
cd DVWA
```
* Check your home directory, DVWA folder should be added. Then change directory to DVWA, and edit with vim to correct the compose.yaml
* change ports section so it looks like this:
```
ports:
    - 4280:80
```
* Save and exit the editor
```
docker compose up -d
```
* From your browser go to your servers IP address with port 4280, for example: http://165.232.172.9:4280, change IP address to your servers IP, default Username: `admin`, Password: `password`. 

Reference: [DVWA GitHub repo](https://github.com/digininja/DVWA), [Docker Documentation](https://docs.docker.com/engine/install/ubuntu/)
### 3. Suricata Installation
* Lets install Suricata now
```
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:oisf/suricata-stable
sudo apt update
sudo apt install suricata jq
```
```
sudo suricata-update
```
* Determine the WAN interface and on which Suricata should be inspecting network packets:
```
root@dvwa-suricata:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 3e:fb:5d:a3:3e:34 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    inet 165.232.172.9/20 brd 165.232.175.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 10.15.0.6/16 brd 10.15.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::3cfb:5dff:fea3:3e34/64 scope link 
       valid_lft forever preferred_lft forever
```
* Since all traffic comes to my server via eth0 interface with 165.232.172.9/20 IP address I choose eth0 interface
```
sudo vim /etc/suricata/suricata.yaml
```
* find af-packets section, and change interface to eth0
```
af-packet:
  - interface: eth0
```
* Then look for rule-files section, and comment out or delete suricata.rules because suricata has huge amount of signatures, and they can trigger even before our Detection, and cause unnecessary noise. And add new file, where we will write our own signatures
```
rule-files:
  #- suricata.rules
  - user.rules # add this, you can call the file however you want
```
* Save and exit the editor
* Note that we will use Suricata on IDS mode, because IPS mode for sure will cause a lot of troubles, and we may cut out the connection to the server, which will force us to reset the server and start from zero

Reference: [Suricata Documentation](https://docs.suricata.io/en/suricata-8.0.2/)