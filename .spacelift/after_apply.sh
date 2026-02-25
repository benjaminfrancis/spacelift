#!/bin/bash
# Spacelift hook: Run after Terraform apply to trigger Ansible configuration
# Uses IAP tunneling for SSH (no external IP required)

set -e

echo "🎯 Running post-apply Ansible configuration..."

# Install Python and Ansible dependencies
pip3 install --quiet ansible google-auth requests google-cloud-secret-manager

# Install Ansible GCP collection
ansible-galaxy collection install google.cloud --force

# Export required environment variables
export GCP_PROJECT="${TF_VAR_project}"
export GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS}"

# Get outputs from Terraform
SECRET_NAME=$(terraform output -raw secret_name)
INSTANCE_NAME=$(terraform output -raw instance_name)
INSTANCE_ZONE=$(terraform output -raw instance_zone)
INTERNAL_IP=$(terraform output -raw instance_internal_ip)

echo "📥 Retrieving SSH private key from Secret Manager..."
gcloud secrets versions access latest --secret="$SECRET_NAME" --project="$GCP_PROJECT" > /mnt/workspace/id_rsa_ansible
chmod 600 /mnt/workspace/id_rsa_ansible

echo "⏳ Waiting for instance to be ready (45 seconds)..."
sleep 45

echo "🔄 Testing IAP SSH connectivity..."
MAX_RETRIES=10
for i in $(seq 1 $MAX_RETRIES); do
  echo "   Attempt $i/$MAX_RETRIES..."
  if gcloud compute ssh ansible@$INSTANCE_NAME \
    --zone="$INSTANCE_ZONE" \
    --project="$GCP_PROJECT" \
    --tunnel-through-iap \
    --ssh-key-file=/mnt/workspace/id_rsa_ansible \
    --command="echo 'SSH OK'" 2>/dev/null; then
    echo "✅ IAP SSH connection successful"
    break
  fi
  sleep 10
done

echo "🚀 Running Ansible playbook..."
cd ansible
ansible-playbook -i gcp_compute_inventory.yml playbook.yml -vv

echo "✅ Ansible configuration complete!"
echo "🌐 Instance internal IP: $INTERNAL_IP"
echo "🔗 To access via IAP tunnel: gcloud compute start-iap-tunnel $INSTANCE_NAME 80 --local-host-port=localhost:8080 --zone=$INSTANCE_ZONE --project=$GCP_PROJECT"
