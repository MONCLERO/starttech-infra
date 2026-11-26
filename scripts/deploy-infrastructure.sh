
#!/usr/bin/env bash
set -euo pipefail

# ----- PROJECT PATHS ----- #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# ----- AWS CONFIGURATION ----- #

AWS_PROFILE="${AWS_PROFILE:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Pin the controller chart version.
CHART_VERSION="3.6.3"

TF_AUTH_ARGS=()

# Use local SSO profile only when static credentials are not supplied.
if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
    echo "Using static AWS credentials."
    unset AWS_PROFILE || true
    unset AWS_DEFAULT_PROFILE || true
    TF_AUTH_ARGS=(-var="aws_profile=")
else
    AWS_PROFILE="${AWS_PROFILE:-starttech-devops}"
    export AWS_PROFILE
    echo "Using AWS profile: $AWS_PROFILE"
fi

export AWS_REGION

# ----- CHECK REQUIRED TOOLS ----- #

for tool in terraform aws kubectl helm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool '$tool' is not installed or not in PATH."
        exit 1
    fi
done

echo "======================================"
echo " StartTech Infrastructure Preparation"
echo "======================================"

# ----- TERRAFORM PREPARATION ----- #

echo "[1/6] Formatting Terraform files..."
terraform -chdir="$TERRAFORM_DIR" fmt -recursive

echo "[2/6] Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init

echo "[3/6] Validating Terraform configuration..."
terraform -chdir="$TERRAFORM_DIR" validate

echo "[4/6] Generating infrastructure plan..."
terraform -chdir="$TERRAFORM_DIR" plan "${TF_AUTH_ARGS[@]}" -out=tfplan

# ----- APPLY INFRASTRUCTURE ----- #

echo "[5/6] Applying infrastructure plan..."
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

rm -f "$TERRAFORM_DIR/tfplan"

echo "Infrastructure deployment completed successfully."

# ----- INSTALL AWS LOAD BALANCER CONTROLLER ----- #

echo "[6/6] Preparing AWS Load Balancer Controller installation..."

# Retrieve Terraform outputs.
CLUSTER_NAME="$(terraform -chdir="$TERRAFORM_DIR" output -raw eks_cluster_name)"
VPC_ID="$(terraform -chdir="$TERRAFORM_DIR" output -raw vpc_id)"
ROLE_ARN="$(terraform -chdir="$TERRAFORM_DIR" output -raw load_balancer_controller_role_arn)"

if [[ -z "$CLUSTER_NAME" || -z "$VPC_ID" || -z "$ROLE_ARN" ]]; then
    echo "ERROR: Required Terraform outputs are missing."
    exit 1
fi

echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"

# ----- VERIFY AWS IDENTITY ----- #

aws sts get-caller-identity

# ----- CONFIGURE KUBECTL ----- #

aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"

# ----- CONFIGURE HELM REPOSITORY ----- #

helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update eks

# ----- INSTALL / UPDATE CRDs ----- #

kubectl apply -f \
    https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml

# ----- INSTALL / UPGRADE CONTROLLER ----- #

helm upgrade --install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    --namespace kube-system \
    --create-namespace \
    --skip-crds \
    --version "$CHART_VERSION" \
    --set clusterName="$CLUSTER_NAME" \
    --set region="$AWS_REGION" \
    --set vpcId="$VPC_ID" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set-string 'serviceAccount.annotations.eks\.amazonaws\.com/role-arn='"$ROLE_ARN"

# ----- VERIFY INSTALLATION ----- #

kubectl rollout status deployment/aws-load-balancer-controller \
    --namespace kube-system \
    --timeout=300s

echo "======================================"
echo " StartTech Infrastructure Deployment"
echo " Completed Successfully!"
echo "======================================"
