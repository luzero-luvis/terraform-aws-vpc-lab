# ── Web security group (public EC2 instances) ─────────────────────────────────
# Stateful — only inbound rules are needed; return traffic is automatic.

resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "HTTP, HTTPS, and SSH inbound; all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH - admin_cidr only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
    Type = "public"
  })
}

# ── Private security group (backend EC2 instances) ────────────────────────────
# Only accepts traffic from the web tier or SSH from within the VPC.

resource "aws_security_group" "private" {
  name        = "${var.name_prefix}-private-sg"
  description = "All traffic from web SG; SSH from VPC CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description     = "All traffic from web tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description = "SSH from anywhere in the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-sg"
    Type = "private"
  })
}
