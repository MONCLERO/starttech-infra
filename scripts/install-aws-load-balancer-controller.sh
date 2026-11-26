
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

# Use the local AWS profile only when one is explicitly supplied.
if [[ -n "$AWS_PROFILE" ]]; then
  export AWS_PROFILE
fi

export AWS_REGION

echo "Preparing AWS Load Balancer Controller installation..."

# ----- RETRIEVE TERRAFORM OUTPUTS ----- #

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

echo "AWS Load Balancer Controller installation completed successfully."
