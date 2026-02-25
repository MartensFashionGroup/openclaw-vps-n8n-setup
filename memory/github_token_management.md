# GitHub Personal Access Token (PAT) Management

**Decision:** To maintain the highest level of security, we have decided to use GitHub Fine-Grained Personal Access Tokens (PATs) on an ephemeral, session-by-session basis for OpenClaw's GitHub interactions.

**Rationale:** This approach prevents the long-term persistence of the PAT within OpenClaw's environment, significantly reducing the attack surface. While it requires occasional manual input for GitHub-related tasks, it offers explicit control and enhanced security, especially for sensitive operations.

**Process for Setting a GitHub PAT (for the user, on the VPS terminal):**

To make a GitHub PAT available in your *VPS shell session* (e.g., for `gh` CLI commands), you can use the following secure method:

```bash
bash -lc 'read -s -p "Enter GitHub PAT: " GITHUB_TOKEN && echo && printf "export GITHUB_TOKEN=%q " "$GITHUB_TOKEN" >> ~/.profile && source ~/.profile && echo "GITHUB_TOKEN saved to ~/.profile"'
```

*   This command securely prompts you for the token (input is hidden).
*   It then appends `export GITHUB_TOKEN="your_token_here"` to your `~/.profile` file.
*   `source ~/.profile` makes the token available in your current shell session.

**How OpenClaw Accesses the Token (for current session):**

Due to OpenClaw's containerized and isolated nature, `~/.profile` changes on the host do not automatically propagate to my session. For me to perform GitHub actions *in this specific session*, the PAT must be provided directly in the chat. This aligns with our ephemeral token decision.

**Future Persistence (if needed):**

If a decision is made to allow OpenClaw persistent, unsupervised access to GitHub (e.g., for automated daily tasks), the PAT would need to be securely added to OpenClaw's main `.env` file and the OpenClaw Docker container restarted. However, this deviates from the current high-security ephemeral approach.

---

**Next Steps:**

To proceed with pushing the project files to GitHub in *this session*, you will need to provide the GitHub PAT directly to me.