# Security Logs & Hardening

## Context:

After establishing the CI/CD pipeline, I integrated **Semgrep (SAST)** and **Trivy (SCA)** to audit the code and infrastructure. The goal was to identify vulnerabilities without blocking the deployment unless absolutely necessary.

### 1. Scanning Execution
I configured a modular CI architecture (`ci/trivy.yml`, `ci/semgrep.yml`) and included them in the main pipeline.
*   **Command:** `trivy fs . --scanners vuln,config`
*   **Command:** `semgrep scan --config auto .`

### 2. Findings & Triage (Backend)

![Semgrep Logs](./screenshots/back-semgrep-logs.png)

![Trivy Logs](./screenshots/back-trivy-logs.png)

1. Infrastructure Issues (Docker)**
Both scanners flagged the Backend Dockerfile as high risk.
*   **Issue:** `DS-0002` (Running as Root). The container defaulted to the `root` user.
*   **Issue:** `DS-0029` (APT overhead). `apt-get install` was running without `--no-install-recommends`.
*   **Issue:** `DS-0026` (No Healthcheck). Trivy failed to see the healthcheck because it was defined in `docker-compose`, not the Dockerfile.

2. Dependency Issues (Python)**
Trivy identified critical CVEs in the developer's `requirements.txt`:
*   `python-jose` (Critical): Algorithm confusion vulnerability.
*   `python-multipart` (High): Path traversal risk.

3. Logic Issues (Python)**
Semgrep flagged `tools/generate_frontend_pack.py` for using `urllib`.
*   **Analysis:** This file was a local helper script, not part of the production application.
*   **Decision:** Marked as **False Positive**.

### Remediation Actions (Backend)

1. Infrastructure Fixes (I implemented these):**
I rewrote the `Dockerfile.prod` to enforce security best practices:
*   Created a system user: `RUN groupadd -g 10001 atsgroup && useradd -u 10001 ...`
*   Switched context: `USER atsuser`
*   Optimized install: Added `--no-install-recommends`.
*   Added explicit Healthcheck: `HEALTHCHECK CMD curl ...`

2. Dependency Triage (Risk Acceptance):**
I cannot update the Python libraries without risking breaking the developer's code.
*   **Action:** I created a `.trivyignore` file to acknowledge the risks (CVE-2024-33663, etc.) and unblock the pipeline. I generated a report for the backend developer to upgrade these packages in the next sprint.

![Semgrep-Result](./screenshots/back-semgrep-final-logs.png)

![Trivy-Result](./screenshots/back-trivy-final-logs.png)

### Findings & Triage (Frontend)

![Semgrep Logs](./screenshots/front-semgrep-logs.png)

![Trivy Logs](./screenshots/front-trivy-logs.png)

1. Infrastructure Issues**
*   **Issue:** The frontend was using `nginx:alpine` which runs as `root` by default.
*   **Issue:** Healthcheck was missing.

2. Dependency Issues**
Trivy found 12 vulnerabilities in `package.json`:
*   `swiper` (Critical): Prototype pollution.
*   `react-router` (Multiple Highs): XSS vulnerabilities.

### Remediation Actions (Frontend)

1. Infrastructure Fixes:**
I completely refactored the Frontend `Dockerfile`:
*   Switched base image to `nginxinc/nginx-unprivileged:alpine` (runs as UID 101).
*   Changed listening port from `80` to `8080` (since non-root users cannot bind port 80).
*   Fixed the `HEALTHCHECK` by pointing `wget` to `127.0.0.1` instead of `localhost` to avoid Alpine's IPv6 resolution bug.

2. Dependency Triage:**
Similar to the backend, updating `react-router` is a breaking change for the application code.
*   **Action:** Added CVEs to `.trivyignore`.
*   **Action:** Reported findings to the frontend developer.

![Semgrep Logs](./screenshots/front-semgrep-final-logs.png)

![Trivy Logs](./screenshots/front-trivy-final-logs.png)

### Final Validation
After pushing the new Dockerfiles and Ignore files:
*   **Semgrep:** 0 Findings.
*   **Trivy:** 0 Findings (Clean pipeline).
*   **Docker Status:** All containers running Healthy as non-root users.