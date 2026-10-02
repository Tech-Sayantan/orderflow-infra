output "repository_urls" {
  description = "Private ECR repository URLs keyed by repository name."
  value = {
    for name, repository in aws_ecr_repository.service :
    name => repository.repository_url
  }
}
