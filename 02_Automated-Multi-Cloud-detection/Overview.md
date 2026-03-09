# Goal
Create a fully automated, idempotent, multi-cloud cyber range using Terraform, Ansible, and GitLab CI/CD. The objective is to deploy an Active Directory environment monitored by Sysmon and Wazuh, with a Linux Gateway running network sensors (Suricata/Zeek), so I can execute Atomic Red Team (ART) attacks and engineer detection rules.

# Context
Running everything on my local Mac was impossible, and Azure drains credits fast. I needed an architecture I could destroy and rebuild automatically in 15 minutes. 
*   **DigitalOcean (1 Droplet):** Acts as the SIEM brain (Wazuh). Needs 4GB RAM.
*   **Azure (3 VMs):** One Ubuntu Linux Gateway (NAT/Router/Sensors) and two Windows Server 2022 machines (Domain Controller and Client). 
*   Because the Windows machines have no public IPs to save money and increase security, everything must jump through the Linux Gateway via an encrypted WireGuard tunnel.

# Steps

## 1. Infrastructure as Code (Terraform)
I used Terraform to build the raw servers across Azure and DigitalOcean. 
Instead of fighting with Ansible for the initial Windows bootstrap, I used Azure's `CustomScriptExtension` to inject PowerShell directly into the VMs at boot time.

*   **Linux Gateway:** Used `custom_data` to instantly enable IPv4 forwarding and configure IPTables NAT, turning it into a router the second it booted.
*   **Windows VMs:** Used Terraform extensions to install OpenSSH, change the default SSH shell to PowerShell via the Registry, and open Port 22. I explicitly used `depends_on = [azurerm_linux_virtual_machine.example]` to ensure the Gateway was providing internet before Windows tried to boot.

## 2. GitLab CI/CD & Dynamic Inventory
I wrote a `.gitlab-ci.yml` pipeline to automate the deployment. Because IPs change every time I run `terraform apply`, I couldn't hardcode them.
*   The pipeline runs `terraform output` to grab the fresh IPs.
*   It dynamically writes an `inventory.ini` file on the fly using `echo`.
*   It securely injects my SSH private key from GitLab Variables into the runner's memory.

## 3. Ansible Configuration (Linux & Network Bridge)
Once Terraform built the metal, Ansible configured the software.
*   Ran a playbook to install Docker and configure a 4GB Swap file on the Linux machines so they wouldn't crash under heavy loads.
*   Wrote a WireGuard playbook that dynamically generated VPN keys on both servers and swapped them using Ansible variables, creating a `10.8.0.x` tunnel between Azure and DO.

## 4. Deploying the Security Stack
*   **SIEM (DO):** Wazuh is heavy. I wrote a playbook to deploy it sequentially. It cleans the directory, clones the official repo, starts the Indexer first, pauses for 2 minutes to let the Java heap stabilize, and *then* starts the Manager and Dashboard.
*   **Sensors (Azure Gateway):** Deployed Suricata and Zeek via custom Dockerfiles. Used `network_mode: host` so they could sniff the physical `eth0` interface. Mapped the logs to `/var/log/suricata` on the host.
*   Configured the Wazuh Agent on the Gateway to read the Suricata/Zeek JSON logs and ship them through the WireGuard tunnel.

## 5. Windows Automation via SSH Jump Host
Configured Ansible to connect to the private Windows IPs by tunneling through the Linux Gateway using `ProxyCommand`.
*   **AD Setup:** Installed AD Domain Services and created `corp.cvpilot.local`.
*   **Client Setup:** Pointed DNS to the AD server and joined the domain.
*   **Security:** Installed Sysmon (with SwiftOnSecurity config) and the Wazuh Agent.
*   **The Nuclear Option:** Wrote a specific playbook to completely uninstall Windows Defender via `win_feature` so it wouldn't block my Red Team attacks.

## 6. Atomic Red Team (ART)
Installed the ART framework using an Ansible `win_shell` task. Forced TLS 1.2 and silently installed the NuGet package provider so the automation wouldn't hang asking for user input.

---

# Troubleshooting & Debugging

**1. The GitLab 400-Minute Limit Trap**
*   *Problem:* While debugging pipelines, I ran out of free GitLab shared runner compute minutes.
*   *Fix:* I bought a cheap $4/mo DO droplet, installed `gitlab-runner`, registered it as a specific tag (`self-hosted`), and ran my own unlimited pipeline executor.

**2. WinRM vs. SSH on Windows Automation**
*   *Problem:* I initially tried to use WinRM over an SSH tunnel to configure Windows. It resulted in constant timeouts and "Dead Worker" errors on my Mac.
*   *Fix:* I switched to Windows Server 2022, used Terraform to install native OpenSSH, and configured Ansible to use `ansible_connection=ssh`.

**3. The `cmd.exe` Interpreter Crash**
*   *Problem:* When Ansible connected to Windows via SSH, it failed with `Parameter format not correct - ;`.
*   *Fix:* Windows OpenSSH defaults to `cmd.exe`. I had to add a registry key via Terraform (`HKLM:\SOFTWARE\OpenSSH\DefaultShell`) to force it to use `powershell.exe` before Ansible connected.

**4. Azure NAT breaking Internal RDP (Asymmetric Routing)**
*   *Problem:* After turning the Linux Gateway into a router, I could no longer RDP into the Windows machines.
*   *Fix:* My initial NAT rule (`-j MASQUERADE`) was masquerading *all* traffic. I fixed it by explicitly ignoring internal destinations (`! -d 10.0.0.0/8`) and adding an `SNAT` rule for internal traffic so Windows would reply to the Gateway instead of dropping the asymmetric packet.

**5. Windows Firewall blocking Internal Routing**
*   *Problem:* The Linux Gateway was correctly forwarding packets (verified via `tcpdump`), but Windows AD wasn't answering domain join requests from the Client.
*   *Fix:* Windows blocks ICMP and unexpected traffic by default. I updated the Terraform bootstrap script to completely disable the Windows Firewall profiles (`Set-NetFirewallProfile -Enabled False`) upon creation.

**6. The "Double Quote" Wazuh Agent Bug**
*   *Problem:* Wazuh agent installed on Windows but stayed "Never Connected." Logs showed `Could not resolve hostname ''10.8.0.1''`.
*   *Fix:* My Ansible command passed single quotes which were written literally into `ossec.conf`. I removed the quotes from the `win_package` arguments and wrote an Ansible regex task to strip them out.

**7. Ansible Apt Lock & Python SSL Bugs**
*   *Problem:* `setup_linux.yml` randomly failed because Ubuntu was running unattended upgrades, or Python 3.12 threw a `cert_file` error when downloading Docker GPG keys.
*   *Fix:* Wrote a `while fuser` loop to make Ansible wait for apt locks to clear. Swapped the Ansible `apt_key` module for a raw `curl` shell command to bypass the Python SSL bug.

**8. Atomic Red Team Missing YAML Dependency**
*   *Problem:* After installing ART, running `Invoke-AtomicTest` threw a `ConvertFrom-Yaml not recognized` error.
*   *Fix:* The silent install missed a dependency. Had to manually run `Install-Module powershell-yaml` inside Windows before the tests would execute.

---

# Conclusion
The infrastructure is now highly elastic. I can destroy the entire Azure and DigitalOcean environment to save money, and rebuild a fully configured, logging-enabled Active Directory Cyber Range with a single click in GitLab CI. Now that the pipeline is stable and Windows Defender is blinded, the next phase is executing ART payloads and writing custom Sigma/Wazuh rules for Detection Engineering.