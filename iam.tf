
resource "aws_iam_openid_connect_provider" "openidconnect" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}
data "aws_iam_policy_document" "oidc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.openidconnect.arn]
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    condition {
      test     = "StringLike"
      values   = ["repo:flyer123/*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}
resource "aws_iam_role" "GithubActionsRole" {
  name               = var.github_role
  assume_role_policy = data.aws_iam_policy_document.oidc.json
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment_bridge" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_dynamodb" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_ec2" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_iam" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_route53" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_s3" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_sqs" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}


resource "aws_iam_role_policy_attachment" "role_policy_attachment_vpc" {
  depends_on = [aws_iam_role.GithubActionsRole]
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = aws_iam_role.GithubActionsRole.name
}