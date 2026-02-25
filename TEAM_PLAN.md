# TEAM_PLAN.md - Agentic Engineering Team Proposal

## Vision
Build a small, agentic Engineering Team that automates routine tasks, accelerates development, and integrates tightly with n8n for cross-system workflows. The team combines human oversight with autonomous agents for repeatable operations.

## Roles
- Lead Data & Engineering Manager (The Manager)
  - Responsibilities: architecture, security posture, coordinating agents, approvals, and escalation.
  - Interfaces: Hostinger VPS, GitHub, n8n, monitoring.

- Data Engineer (agent + human)
  - Responsibilities: data pipelines, ETL, schema design, storage management, backups, and observability.
  - Tools: Python, Airbyte/DBT (later), PostgreSQL, S3-compatible storage.
  - n8n role: trigger and monitor ETL runs, manage data ingress webhooks.

- Coder / DevOps Engineer (agent + human)
  - Responsibilities: deploy & maintain services (n8n, apps), CI/CD, container orchestration, secrets management, and infra-as-code.
  - Tools: Docker, systemd, GitHub Actions, Terraform (later).
  - n8n role: orchestrate deployment workflows, run rollback/playbook automations.

## Workflow & Integration with n8n
- n8n acts as the automation backbone connecting GitHub, VPS, monitoring alerts, and ticketing (issues/PRs).
- Example flows:
  1. New release tag in GitHub → n8n triggers a deployment workflow on the VPS (via secure webhook + signed payload) → DevOps agent performs rollout and reports status back to a GitHub Issue.
  2. Failed cron or backup alert → n8n creates a remediation Issue and notifies the Data Engineer on Telegram/Slack, optionally triggering a safe, pre-approved agent playbook.
  3. PR labeled `infra` → n8n creates a checklist, triggers CI, and if green, opens a deployment PR for human approval.

## Secrets & Security
- Use a secrets store on the VPS (e.g., environment files with strict perms, or HashiCorp Vault for long-term). n8n credentials stored encrypted and rotated regularly.
- Short-lived tokens preferred for agent operations. All agent actions require human approval if they modify production systems.

## Observability & Alerts
- Centralized logging (Loki/ELK) and metrics (Prometheus + Grafana) planned; start simple with log shipping and alerting to Telegram via n8n.
- Healthchecks and scheduled cron jobs monitored; failures trigger n8n flows.

## Onboarding & Incremental Steps
1. Secure VPS baseline: update OS, configure UFW, lock SSH to keys + nonstandard port, install fail2ban.
2. Install Docker, create user `deploy`, and set up deploy keys for GitHub access.
3. Deploy n8n in Docker with persistent storage and encrypted credentials; configure webhooks behind TLS.
4. Create initial n8n flows for repo → CI triggers and alerting.
5. Add Data Engineer tasks: simple ETL pipelines and backup verification flows.

## Governance & Safety
- Human-in-the-loop for any destructive or broadly impactful action.
- Change log + audit trail for every automated action (GitHub Issues, or appended to a local audit file on the VPS).

---
Created by: The Manager (Lead Data & Engineering Manager) — 🛠️
Date: 2026-02-15
