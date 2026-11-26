
#!/usr/bin/env bash

# Stops script when fail
set -euo pipefail

# Find the repository root, regardless of where the script is launched.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo "======================================"
echo " StartTech Infrastructure Preparation"
echo "======================================"

echo "[1/4] Formatting Terraform files..."
terraform -chdir="$TERRAFORM_DIR" fmt -recursive

echo "[2/4] Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init

echo "[3/4] Validating Terraform configuration..."
terraform -chdir="$TERRAFORM_DIR" validate

echo "[4/4] Generating infrastructure plan..."
terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan

echo "======================================"
echo " Infrastructure plan generated!"
echo " Review the plan before applying it."
echo "======================================"
