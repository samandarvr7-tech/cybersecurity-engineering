# Troubleshooting & Debugging Log

**1. The Docker Volume / Database Password Trap**
*   *Issue:* PostgreSQL refused connections even after updating the `.env.prod` file with the correct password.
*   *Cause:* During the first boot, PostgreSQL initializes the database and bakes the password into the Docker Volume. It ignores subsequent `.env` file changes.
*   *Fix:* You must destroy the persistent volume before restarting: `docker-compose down -v`.

**2. Missing Curl in Healthchecks**
*   *Issue:* Docker marked the backend container as `unhealthy` despite the app running correctly.
*   *Cause:* The developer wrote a `HEALTHCHECK` using `curl`, but the base image (`python:3.11-slim`) does not include `curl` by default.
*   *Fix:* Add `RUN apt-get install -y curl` to the Dockerfile.

**3. Database Connection String Errors**
*   *Issue:* Backend crashed on boot trying to connect to the database.
*   *Cause A:* Special characters (like `@` or `/`) in the `POSTGRES_PASSWORD` break the SQLAlchemy URL parser. Use strictly alphanumeric passwords.
*   *Cause B:* Missing the `DATABASE_URL` variable. Developers often default to `localhost`, but inside Docker, the connection string must point to the container alias: `postgresql+asyncpg://user:pass@postgres:5432/db`.

**4. Missing Infrastructure Services**
*   *Issue:* The backend API crashed when trying to upload files.
*   *Cause:* The developer added S3 storage logic but forgot to include the `MinIO` service block in the `docker-compose.yml`.
*   *Fix:* Analyze backend error logs, identify the missing dependency, and request the developer to update the compose file.

**5. Hardcoded Localhost in Frontend Builds**
*   *Issue:* The WebApp loaded successfully, but API requests (like Login) failed with `ERR_CONNECTION_REFUSED`. Network inspection showed requests going to `http://localhost:8000`.
*   *Cause:* React/Vite bakes API URLs into static files at build time. The developer did not configure environment variables properly.
*   *Fix:* Inject a `sed` command into the Frontend `Dockerfile` during the CI build process to aggressively search and replace all developer localhost strings with the production URL.
    ```dockerfile
    ARG VITE_API_URL=https://cvpilot.uz/api
    RUN find src -type f -exec sed -i "s|http://localhost:8000|$VITE_API_URL|g" {} +
    RUN npm run build
    ```

**6. Nginx Trailing Slash (404 Not Found)**
*   *Issue:* Frontend requests to `https://cvpilot.uz/api/auth/login` returned a 404 error from the backend.
*   *Cause:* The Nginx config had a trailing slash on the proxy pass (`proxy_pass http://127.0.0.1:8000/;`). This caused Nginx to strip the `/api/` prefix, sending `/auth/login` to the backend. If the backend expects the `/api` prefix, it will 404.
*   *Fix:* Remove the trailing slash (`proxy_pass http://127.0.0.1:8000;`) so Nginx forwards the exact URI path it receives.

**7. API Contract Mismatch (405 Method Not Allowed)**
*   *Issue:* The frontend "Resumes" page failed to load a list of files, returning a `405` error in the Network tab.
*   *Cause:* Correlated frontend network requests with backend Swagger documentation. The frontend was attempting to call `GET /resumes`, but the backend developer only programmed `POST /resumes` (upload) and `GET /resumes/{id}`. 
*   *Fix:* Identified as a developer logic error. Reported the missing endpoint to the backend team for implementation.