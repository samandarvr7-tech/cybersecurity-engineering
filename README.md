# Security Engineering Portfolio

I am a Security Engineer specializing in building automated, secure infrastructures across hybrid cloud and on-premises environments. In this portfolio, you will find my methodology for mastering Detection Engineering—scaling from defending a single WebApp to securing inter-connected, multi-region cloud architectures. It also includes my production projects, demonstrating how I implement DevSecOps to automate both infrastructure and security.

## Stack

* **Automation (IaC & CI/CD):** `Terraform`, `Ansible`, `GitLab CI/CD`

* **Security & Detection:** `Wazuh (SIEM/XDR)`, `Suricata (IDS/IPS)`, `Zeek (NSM)`, `Semgrep (SAST)`, `Trivy`, `OWASP ZAP (DAST`

* **Cloud Infrastructure:** `Azure`, `DigitalOcean`, `Hetzner`

* **Physical Equipment:** `Mikrotik`, `Netgear`, `Dell Servers`

* **Networking & Core Services:** `Cloudflare`, `Docker`, `Ntopng`, `Jira`, `dnsmasq`, `WireGuard`, `Nginx`, `DVWA`

* **Offensive & Analytical Tools:** `Burp Suite`, `Atomic Red Team`, `Hydra`, `Wireshark`, `Sigma`, `YARA`, `Ghidra`


## Mastering Detection Engineering

**Preview (Bare-Metal Foundation):** Before migrating to the Cloud, I built a physical infrastructure using a Mikrotik router, a Netgear switch, and bare-metal servers. I deployed an inline IPS (Suricata) between the router and switch, allowing me to execute physical network attacks and engineer rules to drop malicious packets in real-time.

### [1. WebApp Detection](01_WebApp_detection)
The baseline phase. I deployed a containerized WebApp monitored by an IDS. Here, I execute manual web attacks (like SQL Injection), analyze the generated raw logs and PCAPs, and write custom signatures to detect and prevent exploitation.

### [2. Automated Multi-Cloud Detection](02_Automated-Multi-Cloud-detection)
Scaling up to a corporate-grade environment. I use Infrastructure as Code (Terraform) to deploy a Multi-Cloud network (Azure & DigitalOcean) linked via WireGuard. The environment includes an Active Directory domain and Windows endpoints monitored by an XDR (Wazuh). I execute lateral movement and domain attacks, using the XDR to perform log pattern analysis and engineer robust correlation rules.

### 3. Advanced Threat Hunting
Transitioning to real-world threat analysis using malware PCAPs from [Malware-Traffic-Analysis.net](https://www.malware-traffic-analysis.net). The focus here is deep packet inspection, identifying C2 beacons, and writing network signatures for active malware campaigns.

### 4. Vulnerability Research (CVEs)
The final stage of the pipeline. Recreating real-world CVEs in isolated testbeds to reverse-engineer the vulnerability. The goal is to write highly effective, behavior-based detection rules for immediate publication on platforms like **SOC Prime**.

---

## [Production Projects](05_Projects)

In my Projects section, I share my DevSecOps experience from live production environments. This includes detailed runbooks on how I provision cloud infrastructure, implement Shift-Left security (SAST/SCA), configure edge protection (Cloudflare/Nginx), and troubleshoot complex pipeline deployments.