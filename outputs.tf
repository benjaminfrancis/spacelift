output "apache_load_balancer_ip" {
  value       = google_compute_global_address.default.address
  description = "Access Apache at http://<this-ip>"
}

output "note" {
  value = "Load balancer may take 5-10 minutes to be fully available after deployment"
}
