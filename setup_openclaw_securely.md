# Secure OpenClaw Setup and Best Practices

This document provides guidance on setting up OpenClaw securely and outlines best practices for its operation, including how to integrate specialized AI agents for various roles.

---

## 1. Installation Prerequisites and Steps

OpenClaw is designed to run within a Docker container on your Hostinger VPS. This section details the necessary prerequisites and the installation process.

### Prerequisites:

*   **Hostinger VPS:** A provisioned VPS with a fresh Ubuntu 22.04 (LTS) or later installation.
*   **Hardened Server:** It is *highly recommended* to first run the `harden_server.sh` script (provided separately) to secure your VPS. This script sets up UFW, Fail2Ban, configures SSH, and creates a non-root user.
*   **Docker & Docker Compose:** OpenClaw runs within Docker. Ensure Docker and Docker Compose (or Docker Compose V2) are installed.

### Docker and Docker Compose Installation:

If you haven't already installed Docker and Docker Compose via the `harden_server.sh` script or manually, follow these steps:

1.  **Update Package Index:**
    ```bash
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    ```
2.  **Add Docker GPG Key:**
    ```bash
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    ```
3.  **Add Docker Repository:**
    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```
4.  **Install Docker Engine:**
    ```bash
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io -y
    ```
5.  **Add your user to the `docker` group:** (Replace `your_user` with your non-root username)
    ```bash
    sudo usermod -aG docker your_user
    newgrp docker # Activate changes for current session, or log out and back in
    ```
6.  **Install Docker Compose (V2 recommended):**
    ```bash
    sudo apt install docker-compose-plugin -y # For Docker Compose V2
    # For older Docker Compose (V1): sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    # sudo chmod +x /usr/local/bin/docker-compose
    ```
7.  **Verify Installation:**
    ```bash
    docker --version
    docker compose version # For V2
    # docker-compose --version # For V1
    ```

### OpenClaw Installation:

OpenClaw typically runs as a Docker container orchestrated by Docker Compose.

1.  **Create a directory for OpenClaw:**
    ```bash
    mkdir ~/openclaw
    cd ~/openclaw
    ```
2.  **Download the OpenClaw Docker Compose file and configuration:**
    (Instructions for obtaining the official Docker Compose files and initial configuration should go here, typically from OpenClaw's official documentation or a provided quickstart.)
    *Example Placeholder:*
    ```bash
    # curl -sSL https://raw.githubusercontent.com/openclaw/openclaw/main/docker-compose.yml -o docker-compose.yml
    # curl -sSL https://raw.githubusercontent.com/openclaw/openclaw/main/.env.example -o .env
    # Edit .env file with your specific configurations (API keys, etc.)
    ```
3.  **Start OpenClaw:**
    ```bash
    docker compose up -d
    ```
4.  **Access OpenClaw:**
    Follow the instructions provided by the OpenClaw documentation to connect to your agent (e.g., via Telegram, WhatsApp, or the web UI).

---

## 2. Recommended User and Permissions for OpenClaw

### Principle of Least Privilege:
OpenClaw should run with the minimum necessary permissions. Avoid running the OpenClaw Docker container as root.

### Dedicated User:
*   **Non-root User:** Ensure the Docker daemon itself does not run as root. The `harden_server.sh` script or manual Docker installation steps should configure your primary non-root user to be part of the `docker` group, allowing them to manage Docker containers without `sudo`.
*   **Docker User:** Inside the container, OpenClaw typically runs as a non-root user. Verify this in the OpenClaw Dockerfile or documentation.

### Volume Permissions:
*   **Workspace:** The OpenClaw workspace directory (e.g., `~/openclaw/workspace`) should be owned by your non-root user on the host system. This ensures OpenClaw can read/write files as intended without elevated privileges.
    ```bash
    sudo chown -R your_user:your_user ~/openclaw/workspace
    ```
    (Replace `your_user` with your non-root username)
*   **Sensitive Files:** Avoid mounting sensitive host directories directly into the OpenClaw container unless absolutely necessary and properly secured.

---

## 3. Securing the Gateway

The OpenClaw Gateway acts as the communication hub. Securing it is paramount.

### Network Exposure:
*   **Firewall:** Ensure your UFW rules (set up by `harden_server.sh`) only expose the necessary ports for OpenClaw (e.g., its web UI port if used, or internal ports for specific integrations).
*   **Reverse Proxy (Recommended):** For public-facing OpenClaw instances (e.g., a web UI), place it behind a reverse proxy like Nginx or Caddy.
    *   **SSL/TLS:** The reverse proxy should handle SSL/TLS termination, ensuring all traffic to OpenClaw is encrypted. Obtain free certificates via Certbot (Let's Encrypt).
    *   **Authentication:** Implement HTTP basic authentication or integrate with an SSO provider at the reverse proxy level to restrict access to the OpenClaw web UI.

### API Keys and Credentials:
*   **Environment Variables:** Store all sensitive API keys, tokens, and credentials as environment variables.
    *   For Docker Compose, use a `.env` file (ensure it's not publicly accessible or committed to version control).
    *   For the OpenClaw itself, pass these as `env` parameters to tool calls or configure them via the Gateway's configuration system.
*   **Avoid Hardcoding:** Never hardcode credentials directly in scripts or configuration files within the OpenClaw workspace that might be exposed.

### Gateway Configuration (`config.yaml` / `.env`):
*   **Review Defaults:** Always review OpenClaw's default configuration settings and adjust them for security.
*   **Access Control:** Configure `allowlist` settings for exec commands and other powerful tools to prevent unintended actions. Restrict which agents or sessions can use which tools.
*   **Logging:** Ensure comprehensive logging is enabled for auditing and security monitoring.

---

## 4. Specific Configuration Files to Adjust for Security

### `openclaw-config.yaml` (or equivalent):
*   **Tool Access:** Carefully define `tool_allowlist` or `tool_denylist` rules to limit agent capabilities. For example, you might restrict `exec` commands to specific scripts or directories, or prevent agents from writing to critical system paths.
*   **Model Access:** Control which models agents can use.
*   **Remote Access:** If enabling remote management, ensure strong authentication and encryption.

### `.env` (for Docker Compose):
*   **API_KEYS:** All API keys (e.g., for `web_search`, `image`, `tts`, `sessions_spawn` if needed) should be stored here as environment variables and referenced in your OpenClaw configuration.
*   **HOST_UID/GID:** If your Docker setup requires specific UID/GID mapping for host volume permissions, ensure these are correctly configured.

---

## 5. Best Practices for Agent Creation and Task Delegation

### Principle of Least Privilege for Agents:
*   **Role-Based Access Control:** Each specialized AI agent (Coder, Security, Product Manager) should have a narrowly defined scope of responsibility and tool access.
*   **Dedicated Workspaces/Sessions:** When spawning sub-agents (via `sessions_spawn`), consider providing them with isolated workspaces or restricting their access to only the necessary files and tools for their specific task.

### Agent Definitions (`IDENTITY.md`):
*   **Clear Roles:** Maintain clear `IDENTITY.md` files for each agent, explicitly stating their responsibilities, capabilities, and limitations. This aids in delegation and prevents scope creep.
*   **Tool Guidance:** Within each agent's `SKILL.md` (or similar guidance), provide explicit instructions on which tools they are authorized to use and under what conditions.

### Task Delegation:
*   **Specific Instructions:** When delegating tasks to agents, provide clear, unambiguous instructions that define the task, expected outcomes, and any security constraints.
*   **Review and Oversight:** As the Engineering Manager, you retain ultimate oversight. Regularly review agent actions and outputs, especially for tasks involving sensitive operations.

---

## 6. Integrating Specialized AI Agents for Roles

### Spawning Sub-Agents:
You will use the `sessions_spawn` tool to initiate tasks for your specialized agents (The Coder, The Guardian, The Strategist).

**Example:** Delegating a coding task to "The Coder"
```python
# To instruct The Coder to write a Python script for a specific task
print(default_api.sessions_spawn(
    agentId="coder", # Assuming 'coder' is configured as a distinct agent ID or label
    task="Write a Python script that takes two numbers as input and returns their sum.",
    label="coder_sum_script" # Optional: A label for this specific sub-session
))
```

**Key Considerations for Integration:**

*   **Agent IDs/Labels:** Ensure your OpenClaw Gateway configuration recognizes and maps logical `agentId`s (like "coder", "security", "product_manager") to specific agent configurations or prompts.
*   **Shared Context:** For tasks that require collaboration or shared information, consider how agents will access relevant files (e.g., shared directories within the workspace) or communicate with each other (e.g., via `sessions_send` or by updating shared status files).
*   **Output Management:** Define how agents should report their progress and final output (e.g., writing to specific files in the workspace, sending structured messages back to the main session).

---

## Conclusion

By following these guidelines, you can establish a secure and efficient OpenClaw environment, leveraging the power of specialized AI agents for your engineering and management needs. Regular review and adaptation of security practices are crucial to maintain a robust system.
