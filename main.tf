terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region" {
  description = "The targetted region of AWS"
  type        = string
  default     = "eu-west-3"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    sid    = "LambdaRolePolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_ecr_policy" {
  statement {
    sid    = "LambdaEcrPolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

data "docker_registry_image" "lambda_image" {
  name = "${aws_ecr_repository.ecr_lambda.repository_url}:latest"
}

resource "aws_ecr_repository" "ecr_lambda" {
  name                 = "aws_log_analysis"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "docker_registry_image" "push_lambda_image" {
  name          = data.docker_registry_image.lambda_image.name
  keep_remotely = true
}

resource "docker_image" "build_lambda_image" {
  name = data.docker_registry_image.lambda_image.name
  build {
    context = "."
    tag     = [data.docker_registry_image.lambda_image.name]
  }
}

resource "aws_ecr_repository_policy" "ecr_lambda_repo_policy" {
  repository = aws_ecr_repository.ecr_lambda.name
  policy     = data.aws_iam_policy_document.lambda_ecr_policy.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_policy.json
}

resource "aws_lambda_function" "aws_log_analysis_lambda" {
  function_name = "aws_log_analysis_lambda"
  package_type  = "Image"
  image_uri     = aws_ecr_repository.ecr_lambda.repository_url
  architectures = ["x86_64"]
  role          = aws_iam_role.lambda_role.arn
  description   = "A lambda that tracks CloudWatch logs for a pattern and notify Teams."
  depends_on    = [aws_ecr_repository.ecr_lambda]

  provisioner "local-exec" {
    command = "docker build -t ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO} . \n$aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com \ndocker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${REPO}"

    environment = {
      ACCOUNT = data.aws_caller_identity.current.account_id
      REGION  = var.aws_region
      REPO    = aws_ecr_repository.ecr_lambda.repository_url
    }
  }

  tags = {
    Name = "aws_log_analysis"
  }
}

resource "aws_cloudwatch_log_group" "error-log" {
  name = "error-log"

  depends_on = [aws_lambda_function.aws_log_analysis_lambda]
}

output "function_url" {
  description = "Endpoint of the lambda"
  value       = aws_lambda_function.aws_log_analysis_lambda.function_url
}
