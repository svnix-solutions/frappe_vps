# =============================================================================
# Frappe VPS - GitOps Makefile
# =============================================================================

PROVIDER ?= hetzner
TERRAFORM_DIR = frappe_terraform/providers/$(PROVIDER)
KAMAL_DIR = frappe_kamal

.PHONY: help init plan apply destroy deploy rollback logs shell backup snapshot setup

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help: ## Show this help
	@echo "Frappe VPS - GitOps Commands"
	@echo ""
	@echo "Infrastructure (Terraform):"
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Preview infrastructure changes"
	@echo "  make apply     - Apply infrastructure changes"
	@echo "  make destroy   - Destroy infrastructure (DANGEROUS)"
	@echo "  make outputs   - Show Terraform outputs"
	@echo ""
	@echo "Application (Kamal):"
	@echo "  make setup     - Initial server setup (first time only)"
	@echo "  make deploy    - Deploy application"
	@echo "  make rollback  - Rollback to previous version"
	@echo "  make restart   - Restart application"
	@echo "  make stop      - Stop application"
	@echo "  make logs      - Stream application logs"
	@echo "  make shell     - Open shell in web container"
	@echo ""
	@echo "Operations:"
	@echo "  make backup    - Create database backup"
	@echo "  make snapshot  - Create volume snapshots"
	@echo "  make status    - Show deployment status"
	@echo ""
	@echo "Options:"
	@echo "  PROVIDER=hetzner|digitalocean|vultr (default: hetzner)"

# -----------------------------------------------------------------------------
# Infrastructure - Terraform
# -----------------------------------------------------------------------------

init: ## Initialize Terraform
	@echo "Initializing Terraform for $(PROVIDER)..."
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Preview infrastructure changes
	@echo "Planning infrastructure for $(PROVIDER)..."
	cd $(TERRAFORM_DIR) && terraform plan

apply: ## Apply infrastructure changes
	@echo "Applying infrastructure for $(PROVIDER)..."
	cd $(TERRAFORM_DIR) && terraform apply

destroy: ## Destroy infrastructure (requires confirmation)
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd $(TERRAFORM_DIR) && terraform destroy

outputs: ## Show Terraform outputs
	@cd $(TERRAFORM_DIR) && terraform output

outputs-json: ## Show Terraform outputs as JSON
	@cd $(TERRAFORM_DIR) && terraform output -json

# -----------------------------------------------------------------------------
# Application - Kamal
# -----------------------------------------------------------------------------

setup: ## Initial server setup (installs Docker, etc.)
	@echo "Setting up server..."
	cd $(KAMAL_DIR) && kamal setup

deploy: ## Deploy application
	@echo "Deploying application..."
	cd $(KAMAL_DIR) && kamal deploy

rollback: ## Rollback to previous version
	@echo "Rolling back..."
	cd $(KAMAL_DIR) && kamal rollback

restart: ## Restart application
	cd $(KAMAL_DIR) && kamal app restart

stop: ## Stop application
	cd $(KAMAL_DIR) && kamal app stop

logs: ## Stream application logs
	cd $(KAMAL_DIR) && kamal app logs -f

logs-web: ## Stream web container logs
	cd $(KAMAL_DIR) && kamal app logs -f

logs-worker: ## Stream worker logs
	cd $(KAMAL_DIR) && kamal accessory logs worker -f

logs-db: ## Stream database logs
	cd $(KAMAL_DIR) && kamal accessory logs db -f

shell: ## Open shell in web container
	cd $(KAMAL_DIR) && kamal app exec -i bash

shell-db: ## Open MySQL shell
	cd $(KAMAL_DIR) && kamal accessory exec db -i mysql -u root -p

console: ## Open Frappe console
	cd $(KAMAL_DIR) && kamal app exec -i "bench console"

# -----------------------------------------------------------------------------
# Operations
# -----------------------------------------------------------------------------

status: ## Show deployment status
	@echo "=== Infrastructure Status ==="
	@cd $(TERRAFORM_DIR) && terraform output -json 2>/dev/null | jq -r '.server_ipv4.value // "Not provisioned"' || echo "Not provisioned"
	@echo ""
	@echo "=== Application Status ==="
	cd $(KAMAL_DIR) && kamal app details 2>/dev/null || echo "Not deployed"

backup: ## Create database backup
	cd $(KAMAL_DIR) && kamal accessory exec db-backup -- restic backup /backup --tag manual

backup-erpnext: ## Create ERPNext backup with files
	cd $(KAMAL_DIR) && kamal app exec "bench --site all backup --with-files"

backup-list: ## List available backups
	cd $(KAMAL_DIR) && kamal accessory exec db-backup -- restic snapshots

snapshot: ## Create volume snapshots (Hetzner only)
	@echo "Creating volume snapshots..."
	@./scripts/snapshot.sh

# -----------------------------------------------------------------------------
# Development
# -----------------------------------------------------------------------------

lint: ## Lint Terraform files
	cd $(TERRAFORM_DIR) && terraform fmt -check -recursive

fmt: ## Format Terraform files
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && terraform validate

# -----------------------------------------------------------------------------
# Sync Configuration
# -----------------------------------------------------------------------------

sync-host: ## Update Kamal config with Terraform output
	@echo "Syncing server IP to Kamal config..."
	@IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw server_ipv4 2>/dev/null) && \
	if [ -n "$$IP" ]; then \
		echo "Server IP: $$IP"; \
		echo "Update $(KAMAL_DIR)/config/deploy.yml with this IP"; \
	else \
		echo "No server provisioned yet. Run 'make apply' first."; \
	fi
