
#!/usr/bin/env bash
set -euo pipefail

# ----- PROJECT PATHS ----- #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# ----- AWS CONFIGURATION ----- #

AWS_PROFILE="${AWS_PROFILE:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CHART_VERSION="3.6.3"

export AWS_REGION
export AWS_DEFAULT_REGION="$AWS_REGION"

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

# ----- CHECK REQUIRED TOOLS ----- #

for tool in terraform aws kubectl helm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool '$tool' is not installed or not in PATH."
        exit 1
    fi
done

echo "======================================"
echo " StartTech Infrastructure Deployment"
echo "======================================"

# ----- VERIFY AWS IDENTITY ----- #

echo "[1/7] Verifying AWS identity..."
aws sts get-caller-identity

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
STATE_BUCKET="starttech-terraform-state-${ACCOUNT_ID}"

echo "AWS Account: $ACCOUNT_ID"
echo "Terraform State Bucket: $STATE_BUCKET"

# ----- BOOTSTRAP TERRAFORM STATE BUCKET ----- #

echo "[2/7] Checking Terraform state bucket..."

if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo "Terraform state bucket already exists."
else
    echo "Creating Terraform state bucket..."

    CREATE_BUCKET_ARGS=(--bucket "$STATE_BUCKET")

    if [[ "$AWS_REGION" != "us-east-1" ]]; then
        CREATE_BUCKET_ARGS+=(--create-bucket-configuration "LocationConstraint=$AWS_REGION")
    fi

    aws s3api create-bucket "${CREATE_BUCKET_ARGS[@]}"

    aws s3api wait bucket-exists --bucket "$STATE_BUCKET"

    echo "Terraform state bucket created."
fi

# Enable versioning.
aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption.
aws s3api put-bucket-encryption \
    --bucket "$STATE_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block all public access.
aws s3api put-public-access-block \
    --bucket "$STATE_BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enforce bucket-owner ownership.
aws s3api put-bucket-ownership-controls \
    --bucket "$STATE_BUCKET" \
    --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'

echo "Terraform state bucket is secured."

# ----- TERRAFORM PREPARATION ----- #

echo "[3/7] Formatting Terraform files..."
terraform -chdir="$TERRAFORM_DIR" fmt -recursive

echo "[4/7] Initializing Terraform with S3 remote state..."

terraform -chdir="$TERRAFORM_DIR" init -reconfigure \
    -backend-config="bucket=$STATE_BUCKET" \
    -backend-config="key=starttech/terraform.tfstate" \
    -backend-config="region=$AWS_REGION" \
    -backend-config="encrypt=true" \
    -backend-config="use_lockfile=true"

echo "[5/7] Validating Terraform configuration..."
terraform -chdir="$TERRAFORM_DIR" validate

# ----- PLAN AND APPLY ----- #

echo "[6/7] Generating infrastructure plan..."

terraform -chdir="$TERRAFORM_DIR" plan \
    "${TF_AUTH_ARGS[@]}" \
    -out=tfplan

echo "Applying infrastructure plan..."

terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

rm -f "$TERRAFORM_DIR/tfplan"

echo "Terraform infrastructure deployment completed."

# ----- INSTALL AWS LOAD BALANCER CONTROLLER ----- #

echo "[7/7] Installing AWS Load Balancer Controller..."

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

# Configure kubectl.
aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"

# Configure Helm repository.
helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update eks

# Install/update controller CRDs.
kubectl apply -f \
    https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml

# Install/upgrade controller.
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

# Verify controller rollout.
kubectl rollout status deployment/aws-load-balancer-controller \
    --namespace kube-system \
    --timeout=300s

echo "======================================"
echo " StartTech Infrastructure Deployment"
echo " Completed Successfully!"
echo "======================================"
