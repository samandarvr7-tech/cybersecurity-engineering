# AI Resume Analyzer: Cloud Infrastructure & DevSecOps

## Project Overview
I designed, secured, and automated the production infrastructure for an AI-powered Resume Analyzer and Applicant Tracking System (ATS). The application allows HR professionals to upload job descriptions and candidate resumes, using an NLP engine (via n8n and OpenAI) to automatically score and extract matched/missing skills.

While the development team was responsible for writing the business logic in Python (FastAPI) and React (Vite), **my role as the Cloud & DevSecOps Engineer** was to build the bridge between their code and a secure, live production environment. 

I was completely responsible for server provisioning, reverse proxy configuration, edge security, containerization of the frontend, CI/CD automation, and integrating vulnerability scanning into the deployment lifecycle.

## 🛠 My Role & Contributions
* **Cloud Infrastructure:** Provisioned and managed Linux servers on Hetzner Cloud.
* **Edge Security & Routing:** Configured **Cloudflare** (Strict SSL) and **Nginx** as a reverse proxy with custom rate-limiting (`limit_req_zone`) to mitigate DDoS attacks and hide backend ports.
* **Containerization:** Built optimized, multi-stage `Dockerfiles` (implementing non-root users and health checks) and orchestrated the microservices using `docker-compose`.
* **CI/CD Automation:** Built modular **GitLab CI/CD pipelines** to automatically build, scan, and deploy code to the production server via SSH and `rsync`.
* **DevSecOps (Shift-Left Security):** Integrated **Semgrep (SAST)** for custom code logic scanning and **Trivy (SCA)** to detect vulnerable third-party dependencies (finding and reporting critical CVEs in JWT and frontend routing libraries).
* **Troubleshooting:** Debugged critical production issues, including Nginx path routing collisions, Docker volume persistence traps, and frontend hardcoded-localhost build errors.