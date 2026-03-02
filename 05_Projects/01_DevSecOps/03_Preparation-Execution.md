# Steps

1. **Repository & CI/CD Setup:** Create separate GitLab repositories for Backend and Frontend to isolate deployments. Configure GitLab CI/CD variables (`SERVER_IP`, `SSH_PRIVATE_KEY`) to enable automated SSH access to the Hetzner server.

2. **Backend Containerization & Secrets:** Review the Backend `README.md` or `PRODUCTION_SETUP.md` to identify required environment variables (e.g., `JWT_SECRET`, `POSTGRES_PASSWORD`, `S3_ACCESS_KEY`). Inject these into GitLab CI/CD Variables. Analyze the dependency file (`requirements.txt`) to ensure the provided `Dockerfile` and `docker-compose.yml` are correctly structured.

3. **Firewall (UFW) Configuration:** Secure the host network by allowing only standard web traffic. All internal Docker ports must be blocked from the public internet.
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 8000/tcp  # Block direct backend access
ufw deny 5433/tcp  # Block direct DB access
ufw enable
```

4. **Edge Security & Reverse Proxy:** Register the domain in `Cloudflare` (DNS Only/Flexible mode initially). Deploy `Nginx` on the host server to act as a Reverse Proxy and Rate Limiter. Install `Certbot` to generate SSL certificates, then upgrade Cloudflare to **Full (Strict)** mode for end-to-end encryption.

> *Nginx Config Note:* We use `$http_cf_connecting_ip` instead of `$binary_remote_addr` for rate limiting so we don't accidentally ban Cloudflare's proxy IPs.

```nginx
server {
    server_name cvpilot.uz www.cvpilot.uz;

    # Frontend Routing
    location / {
        limit_req zone=ats_limit burst=10 nodelay;
        proxy_pass http://127.0.0.1:3000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $http_cf_connecting_ip;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API Routing (Note: NO trailing slash on proxy_pass)
    location /api/ {
        limit_req zone=ats_limit burst=10 nodelay;
        proxy_pass http://127.0.0.1:8000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $http_cf_connecting_ip;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/cvpilot.uz/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/cvpilot.uz/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
```

5. **Frontend Containerization:** Analyze the Frontend repo. Locate the `package.json` to identify the build framework (Vite/React). Create a custom Multi-Stage `Dockerfile` (Node.js builder -> Nginx Alpine server) and write a `.gitlab-ci.yml` to automate the build and deployment.

6. **DevSecOps Integration:** Integrate SAST (`Semgrep`) and SCA (`Trivy`) into the GitLab CI pipelines to identify critical vulnerabilities in custom code and third-party dependencies without blocking the deployment.

```yaml
# SAST (Semgrep)
semgrep_scan:
  stage: security
  image: 
    name: returntocorp/semgrep:latest
    entrypoint: [""] # Required to prevent Docker Volume crash in GitLab
  script:
    - echo "Starting Semgrep SAST Scan..."
    - semgrep scan --config auto .
  allow_failure: true

# SCA (Trivy)
trivy_scan:
  stage: security
  image: 
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - echo "Starting Trivy Vulnerability Scan..."
    - trivy fs . --scanners vuln,config --exit-code 0 --no-progress
  allow_failure: true
```

7. **Testing & QA:** Perform manual end-to-end testing via the WebApp UI and backend Swagger docs. Report any business logic or API contract failures to the developers.