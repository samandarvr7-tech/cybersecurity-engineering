# Tech Stack Used

| Category | Technologies |
| :--- | :--- |
| **Cloud & Network** | Hetzner, Cloudflare (WAF/DNS), UFW (Firewall) |
| **Web Server** | Nginx, Certbot (Let's Encrypt TLS 1.3) |
| **Containerization** | Docker, Docker Compose |
| **CI/CD & Automation** | GitLab CI, Bash, SSH, Rsync, Terraform |
| **Security Scanning** | Semgrep (SAST), Trivy (SCA/Container) |
| **Deployed App Stack** | FastAPI, React (Vite), PostgreSQL, MinIO (S3), n8n, Redis |

---

# Infrastructure as Code (Terraform)
To ensure the infrastructure is reproducible, I used **Terraform** to automate the provisioning of the Hetzner VPS and inject my SSH deployment keys. 

Here is the `main.tf` configuration I used to spin up the production environment:

```hcl
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  # Hetzner API token injected securely
  token = "<Your_Tokens_Here>"
}

resource "hcloud_ssh_key" "server_key" {
  name       = "deploy-key"
  public_key = file("~/.ssh/id_rsa.pub") 
}

resource "hcloud_server" "prod" {
  name        = "resume-analyzer"
  image       = "ubuntu-24.04"
  server_type = "cpx22" 
  location    = "nbg1" 
  ssh_keys    = [hcloud_ssh_key.server_key.id]
}

output "server_ip" {
  value = hcloud_server.prod.ipv4_address
}
```

---

## 📂 Repository Navigation

To see exactly how I built, secured, and debugged this environment, please check the detailed engineering runbooks in this repository:

* 📄 **[Preparation_Execution.md](./Preparation_Execution.md)** - Step-by-step guide on how I configured Nginx, automated the GitLab CI/CD pipelines, and integrated Semgrep and Trivy.
* 📄 **[Troubleshooting.md](./Troubleshooting.md)** - A detailed log of the production incidents I faced (e.g., React localhost build traps, Nginx trailing slash 404s, Docker volume locks) and how I engineered solutions for them.