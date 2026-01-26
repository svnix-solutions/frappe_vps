# Frappe VPS

GitOps deployment system for Frappe/ERPNext on VPS infrastructure.

## Overview

This repository orchestrates the deployment of ERPNext using:

- **[frappe_terraform](./frappe_terraform/)** - Infrastructure provisioning (servers, volumes, firewalls)
- **[frappe_kamal](./frappe_kamal/)** - Application deployment (Docker, zero-downtime deploys)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions                            │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ infra-plan  │    │ infra-apply │    │   deploy    │         │
│  │ (on PR)     │    │ (on merge)  │    │ (on merge)  │         │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘         │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Terraform     │  │   Terraform     │  │     Kamal       │
│   Plan          │  │   Apply         │  │     Deploy      │
└─────────────────┘  └────────┬────────┘  └────────┬────────┘
                              │                    │
                              ▼                    ▼
                     ┌─────────────────────────────────────┐
                     │            VPS Server               │
                     │  ┌─────────────────────────────┐   │
                     │  │  Docker + ERPNext            │   │
                     │  └─────────────────────────────┘   │
                     │            │                        │
                     │            ▼                        │
                     │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
                     │  │sites│ │ db  │ │back │ │logs │  │
                     │  │     │ │data │ │ups  │ │     │  │
                     │  └─────┘ └─────┘ └─────┘ └─────┘  │
                     │       Block Storage Volumes        │
                     └─────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Kamal](https://kamal-deploy.org/) >= 2.0
- Cloud provider account (Hetzner, DigitalOcean, or Vultr)
- Docker Hub account

### 1. Clone with Submodules

```bash
git clone --recursive https://github.com/svnix-solutions/frappe_vps.git
cd frappe_vps
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

### 3. Provision Infrastructure

```bash
# Configure Terraform
cp frappe_terraform/providers/hetzner/terraform.tfvars.example \
   frappe_terraform/providers/hetzner/terraform.tfvars
# Edit terraform.tfvars with your Hetzner token and SSH keys

# Initialize and apply
make init
make plan
make apply
```

### 4. Deploy Application

```bash
# Initial setup (first time only)
make setup

# Deploy ERPNext
make deploy
```

## Commands

### Infrastructure

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform |
| `make plan` | Preview infrastructure changes |
| `make apply` | Apply infrastructure changes |
| `make destroy` | Destroy infrastructure |
| `make outputs` | Show Terraform outputs |

### Application

| Command | Description |
|---------|-------------|
| `make setup` | Initial server setup |
| `make deploy` | Deploy application |
| `make rollback` | Rollback to previous version |
| `make restart` | Restart application |
| `make logs` | Stream application logs |
| `make shell` | Open shell in container |

### Operations

| Command | Description |
|---------|-------------|
| `make backup` | Create database backup |
| `make snapshot` | Create volume snapshots |
| `make status` | Show deployment status |

## GitHub Actions Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| `infra-plan.yml` | PR to main | Terraform plan + PR comment |
| `infra-apply.yml` | Push to main | Terraform apply |
| `deploy.yml` | Push to main | Kamal deploy |
| `backup.yml` | Daily at 2 AM | Database + volume backup |

### Required Secrets

Configure these in your GitHub repository settings:

| Secret | Description |
|--------|-------------|
| `HCLOUD_TOKEN` | Hetzner Cloud API token |
| `SSH_KEY_NAMES` | JSON array of SSH key names: `["key1", "key2"]` |
| `SSH_PRIVATE_KEY` | Private SSH key for server access |
| `DEPLOY_HOST` | Server IP address |
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_HUB_TOKEN` | Docker Hub access token |
| `MARIADB_ROOT_PASSWORD` | MariaDB root password |
| `ADMIN_PASSWORD` | ERPNext admin password |
| `ENCRYPTION_KEY` | ERPNext encryption key |

### Repository Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_NAME` | `frappe` | Project name for resource naming |
| `ENVIRONMENT` | `production` | Environment name |
| `SERVER_TYPE` | `cx31` | Hetzner server type |
| `SERVER_LOCATION` | `fsn1` | Hetzner datacenter |
| `SITE_NAME` | `erp.example.com` | ERPNext site domain |

## Disaster Recovery

### Backups

- **Database**: Daily Restic backups with 7-day retention
- **Files**: Included in ERPNext backup
- **Volumes**: Snapshottable for point-in-time recovery

### Recovery Process

1. Create new server from Terraform
2. Restore volumes from snapshots (or attach existing volumes)
3. Deploy application with Kamal
4. Restore database if needed

```bash
# Create infrastructure (new server, existing volumes)
make apply

# Deploy application
make setup
make deploy

# Restore database (if needed)
make shell
bench --site sitename restore /path/to/backup.sql.gz
```

## Directory Structure

```
frappe_vps/
├── .github/
│   └── workflows/
│       ├── infra-plan.yml      # Terraform plan on PR
│       ├── infra-apply.yml     # Terraform apply on merge
│       ├── deploy.yml          # Kamal deploy
│       └── backup.yml          # Scheduled backups
├── frappe_kamal/               # (submodule) Kamal config
├── frappe_terraform/           # (submodule) Terraform IaC
├── scripts/
│   └── snapshot.sh             # Volume snapshot helper
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

## License

MIT
