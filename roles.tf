resource "aws_iam_role" "GithubActionsRole" {
  name = "GithubActionsRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_bridge" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
  role       = "GithubActionsRole"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_dynamodb" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_ec2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_iam" {
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_route53" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_sqs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = "GithubActionsRole"
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = "GithubActionsRole"
}

resource "aws_iam_openid_connect_provider" "openidconnect" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["d89e3bd43d5d909b47a18977aa9d5ce36cee184c"]
}