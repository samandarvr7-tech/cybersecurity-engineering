variable "do_token" {
  sensitive = true
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "wazuh-server" {
  name       = "wazuh-server"
  public_key = var.ssh_public_key
}

resource "digitalocean_droplet" "wazuh-server" {
  image   = "ubuntu-24-04-x64"
  name    = "wazuh-server"
  region  = "sgp1"
  size    = "s-2vcpu-4gb"
  ssh_keys = [digitalocean_ssh_key.wazuh-server.fingerprint]
}

output "siem_public_ip" {
  value = digitalocean_droplet.wazuh-server.ipv4_address
}