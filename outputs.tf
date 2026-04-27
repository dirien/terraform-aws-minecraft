output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = aws_instance.this.arn
}

output "instance_public_ip" {
  description = "Public IP address (EIP if enabled, otherwise the auto-assigned address)."
  value       = var.eip_enabled ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance."
  value       = aws_instance.this.public_dns
}

output "instance_private_ip" {
  description = "Private IP address."
  value       = aws_instance.this.private_ip
}

output "ami_id" {
  description = "AMI ID used for the instance."
  value       = local.ami_id
}

output "security_group_id" {
  description = "Security group ID."
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the instance, if created by this module."
  value       = try(aws_iam_role.this[0].arn, null)
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN, if created by this module."
  value       = try(aws_iam_instance_profile.this[0].arn, null)
}

output "data_volume_id" {
  description = "ID of the persistent data EBS volume, if created."
  value       = try(aws_ebs_volume.data[0].id, null)
}

output "eip_address" {
  description = "Elastic IP address, if allocated."
  value       = try(aws_eip.this[0].public_ip, null)
}

output "route53_record_fqdn" {
  description = "FQDN of the created Route 53 record, if any."
  value       = try(aws_route53_record.this[0].fqdn, null)
}

output "ssm_connect_command" {
  description = "AWS CLI command to start an SSM Session Manager shell on the instance."
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}
