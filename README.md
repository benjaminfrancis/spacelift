# 🚀 Terraform + Ansible on GCP (via Spacelift)

This demo shows how to provision GCP infrastructure with Terraform and configure it using Ansible, automated through Spacelift. This is the **GCP equivalent** of the AWS demo at [N4si/spacelift_demo](https://github.com/N4si/spacelift_demo).

## 📋 Overview

**Infrastructure as Code:** Terraform provisions:
- VPC Network and Subnet
- Compute Engine instance (Debian 12, e2-micro)
- Firewall rules (SSH, HTTP)
- SSH key pair (stored in Secret Manager)
- Public IP for direct access

**Configuration Management:** Ansible configures:
- Apache web server installation
- Custom HTML page deployment
- Service management and verification

## 🏗️ Architecture

```
Spacelift Workflow:
  1. Terraform provisions GCP infrastructure
  2. Outputs instance IP and SSH key location
  3. After_apply hook triggers Ansible
  4. Ansible configures Apache on the instance
  5. Website accessible at instance public IP
```

## 📁 Project Structure

```
.
├── main.tf                          # Terraform main configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Outputs for Ansible integration
├── terraform.tfvars                 # Variable values (gitignored)
├── ansible/
│   ├── playbook.yml                 # Ansible playbook for Apache
│   ├── gcp_compute_inventory.yml    # GCP dynamic inventory
│   └── ansible.cfg                  # Ansible configuration
├── .spacelift/
│   └── after_apply.sh               # Post-apply Ansible execution hook
└── deploy.sh                        # Local deployment orchestration
```

## 🚀 Deployment Options

### Option 1: Spacelift (Automated)

1. **Create Spacelift Stack:**
   - Connect to this repository
   - Set project root to `/`
   - Add GCP credentials as environment variables

2. **Configure Stack Settings:**
   ```
   Environment Variables:
   - TF_VAR_project = your-gcp-project-id
   - GOOGLE_APPLICATION_CREDENTIALS = /path/to/service-account.json
   ```

3. **Enable After-Apply Hook:**
   - Spacelift will automatically run `.spacelift/after_apply.sh`
   - This hook retrieves SSH keys and runs Ansible

4. **Trigger Deployment:**
   - Push to main branch or manually trigger
   - Terraform Apply → Ansible Configure (automatically)

### Option 2: Local Deployment

```bash
# 1. Initialize Terraform
terraform init

# 2. Set your GCP project
export TF_VAR_project="your-gcp-project-id"

# 3. Plan and apply
terraform plan
terraform apply

# 4. Run deployment script (retrieves keys + runs Ansible)
chmod +x deploy.sh
./deploy.sh
```

## 🔑 Key Differences from AWS Version

| Feature | AWS (Original) | GCP (This Repo) |
|---------|---------------|-----------------|
| **Provider** | `aws` | `google` |
| **Compute** | EC2 instance | Compute Engine instance |
| **Network** | VPC (aws_vpc) | VPC Network (google_compute_network) |
| **SSH Keys** | AWS Key Pair + SSM | TLS resource + Secret Manager |
| **Inventory** | `aws_ec2` plugin | `gcp_compute` plugin |
| **Filtering** | EC2 tags | GCE labels |
| **User Data** | cloud-init | metadata_startup_script |

## 📊 Terraform Resources

- `tls_private_key` - Generate SSH key pair
- `google_secret_manager_secret` - Store private key securely
- `google_compute_network` - VPC network
- `google_compute_subnetwork` - Subnet
- `google_compute_firewall` - SSH and HTTP access
- `google_compute_instance` - VM with public IP

## 🔧 Ansible Configuration

**Playbook Tasks:**
1. Update APT cache
2. Install Apache2
3. Start and enable Apache service
4. Deploy custom HTML page
5. Verify Apache is listening on port 80

**Dynamic Inventory:**
- Uses `google.cloud.gcp_compute` plugin
- Filters by label: `managed_by=ansible`
- Filters by status: `RUNNING`
- Uses public IP for connection

## 🌐 Access Your Application

After deployment completes:

```bash
# Get the instance IP
terraform output instance_public_ip

# Test the web server
curl http://<INSTANCE_IP>
```

You should see a custom-styled page: **"Hello from Ansible on GCP! 🚀"**

## 🔐 Security Notes

- SSH private key stored in GCP Secret Manager
- Public IP assigned for demo purposes only
- Firewall rules limit access to ports 22 and 80
- For production: use IAP tunneling instead of public IPs

## 🛠️ Prerequisites

**Local Development:**
- Terraform >= 1.0
- Ansible >= 2.9
- GCP CLI (`gcloud`)
- Python 3
- GCP service account with permissions:
  - Compute Admin
  - Secret Manager Admin
  - Service Account User

**Spacelift:**
- GCP credentials configured in stack
- After-apply hooks enabled

## 📚 Helpful Commands

```bash
# Check Terraform outputs
terraform output

# Manually retrieve SSH key
gcloud secrets versions access latest --secret=ansible-ssh-private-key

# Test Ansible connectivity
ansible all -i ansible/gcp_compute_inventory.yml -m ping

# Run Ansible playbook manually
cd ansible
ansible-playbook -i gcp_compute_inventory.yml playbook.yml

# Destroy infrastructure
terraform destroy
```

## 🐛 Troubleshooting

**SSH Connection Issues:**
```bash
# Check instance is running
gcloud compute instances list

# Check firewall rules
gcloud compute firewall-rules list

# Verify SSH key in instance metadata
gcloud compute instances describe ansible-demo-instance --zone=us-central1-a
```

**Ansible Inventory Issues:**
```bash
# List discovered hosts
ansible-inventory -i ansible/gcp_compute_inventory.yml --list

# Test GCP authentication
gcloud auth list
```

## 📖 References

- 🌐 [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- 🧰 [Ansible GCP Collection](https://docs.ansible.com/ansible/latest/collections/google/cloud/index.html)
- ☁️ [Spacelift Documentation](https://docs.spacelift.io/)
- 🎥 [Original AWS Demo Video](https://youtu.be/geSwD6M1pQs)

## 📝 License

This is a demo project for educational purposes.
