output "instance_internal_ip" {
  description = "Internal IP of the GCE instance"
  value       = google_compute_instance.demo_instance.network_interface[0].network_ip
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.demo_instance.name
}

output "instance_zone" {
  description = "Zone of the compute instance"
  value       = google_compute_instance.demo_instance.zone
}

output "secret_name" {
  description = "Secret Manager secret name containing SSH private key"
  value       = google_secret_manager_secret.ansible_private_key.secret_id
}

output "iap_tunnel_command" {
  description = "Command to create IAP SSH tunnel for accessing the instance"
  value       = "gcloud compute start-iap-tunnel ${google_compute_instance.demo_instance.name} 80 --local-host-port=localhost:8080 --zone=${var.zone} --project=${var.project}"
}
