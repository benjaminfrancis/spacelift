terraform {
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

# Generate SSH key pair for Ansible access
resource "tls_private_key" "ansible_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "ansible_private_key" {
  secret_id = "ansible-ssh-private-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ansible_private_key_version" {
  secret      = google_secret_manager_secret.ansible_private_key.id
  secret_data = tls_private_key.ansible_key.private_key_pem
}

# Create VPC
resource "google_compute_network" "vpc_network" {
  name                    = "ansible-demo-vpc"
  auto_create_subnetworks = false
}

# Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "ansible-demo-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall rule for SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-ansible"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ansible-managed"]
}

# Firewall rule for HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-ansible"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Compute Engine Instance (equivalent to EC2)
resource "google_compute_instance" "demo_instance" {
  name         = "ansible-demo-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    
    # External IP for direct access (like AWS EC2)
    access_config {
      # Ephemeral IP
    }
  }

  # Add SSH public key to instance metadata
  metadata = {
    ssh-keys = "ansible:${tls_private_key.ansible_key.public_key_openssh}"
  }

  # Install Python for Ansible (equivalent to AWS user_data)
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip
  EOF

  tags = ["ansible-managed", "http-server"]

  labels = {
    environment = "demo"
    managed_by  = "ansible"
  }
}
