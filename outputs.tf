output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
output "webapp_ecr_uri" {
  value = aws_ecr_repository.webapp.repository_url
}
output "mysql_ecr_uri" {
  value = aws_ecr_repository.mysql.repository_url
}
output "private_key_path" {
  value = "${path.cwd}/clo835_deployer.pem"
}
