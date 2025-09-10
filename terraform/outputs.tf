output "staging_instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the staging EC2 instance"
}

output "staging_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "HTTP URL of the staging environment"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URI of the ECR repository (without tag)"
}
