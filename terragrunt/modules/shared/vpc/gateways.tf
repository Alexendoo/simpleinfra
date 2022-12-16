// The internet gateway allows communication from and to the Internet, on both
// IPv4 and IPv6. It's used by public subnets.

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

// The egress-only internet gateway allows only IPv6 connections to the
// Internet. IPv4 connections or IPv6 connections from the internet are not
// supported. It's used by private subnets.

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.vpc.id
}

// The gateway endpoints allow requests to S3 and DynamoDB from private subnets
// without going through the NAT gateway.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
}

// The NAT gateway allows IPv4 connections to the public internet in private
// subnets, without allowing inbound connections. A NAT gateway is created
// inside the first public subnet of each AZ.

resource "aws_eip" "nat" {
  for_each = toset(values(var.public_subnets)) # Name of the AZs

  vpc = true
  tags = {
    Name = "${var.name}--nat-${each.value}"
  }
}

resource "aws_nat_gateway" "nat" {
  # Transform a map of subnet numbers and AZ names:
  #
  #   {"0" = "usw1-az1", "1" = "usw1-az3", "2" = "usw1-az1", "3" = "usw1-az3"}
  #
  # ...into a map of AZ names and the first subnet number in that AZ:
  #
  #   {"usw1-az1" = "0", "usw1-az3" = "1"}
  #
  for_each = {
    for az, subnets in transpose({
      for num, az in var.public_subnets : num => [az]
    }) : az => subnets[0]
  }

  subnet_id     = aws_subnet.public[each.value].id
  allocation_id = aws_eip.nat[each.key].id

  tags = {
    Name = "${var.name}--nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.igw]
}
