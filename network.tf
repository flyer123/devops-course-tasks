data "aws_availability_zones" "available-azs" {
  state = "available"
}

resource "aws_vpc" "vpc-tf" {
  cidr_block = var.cidr_block_vpc
}

resource "aws_subnet" "public-subnets-tf_1" {
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.0.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[0]

}

resource "aws_subnet" "public-subnets-tf_2" {
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[1]
}

resource "aws_subnet" "private-subnets-tf_1" {
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[0]

}

resource "aws_subnet" "private-subnets-tf_2" {
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[1]

}

