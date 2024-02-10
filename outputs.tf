output "arn" {
  value       = aws_cloudfront_distribution.dist.arn
  description = "Distribution ARN"
}

output "zone_id" {
  value       = aws_cloudfront_distribution.dist.hosted_zone_id
  description = "Distribution hosted zone ID"
}

output "domain_name" {
  value       = aws_cloudfront_distribution.dist.domain_name
  description = "Distribution domain name"
}
