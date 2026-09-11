provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project       = "aws-cloud-portfolio"
      ProjectNumber = "03"
      Environment   = var.environment
      ManagedBy     = "terraform"
    }
  }
}
