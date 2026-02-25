output "instance_public_ip" {
  description = "Public IP of the GCE instance"
  value       = google_compute_instance.demo_instance.network_interface[0].access_config[0].nat_ip
}

output "secret_name" {
  description = "Secret Manager secret name containing SSH private key"
  value       = google_secret_manager_secret.ansible_private_key.secret_id
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.demo_instance.name
}

output "instance_zone" {
  description = "Zone of the compute instance"
  value       = google_compute_instance.demo_instance.zone
}
