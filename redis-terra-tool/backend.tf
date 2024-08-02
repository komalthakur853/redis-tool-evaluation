terraform {
  backend "s3" {
    bucket = "cicd-terraform-redis"
    key    = "jenkins/terraform.tfstate"
    region = "us-east-2"
  }
}
