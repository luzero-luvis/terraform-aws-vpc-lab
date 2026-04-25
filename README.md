# terraform-aws-vpc-lab

A fully modular Terraform lab for mastering AWS VPC networking — two peered VPCs covering every core concept: IGW, NAT, route tables, NACLs, security groups, and VPC peering. Everything controlled from a single `terraform.tfvars`.

---

## Network Architecture

```mermaid
flowchart TB
    Internet(["🌐 Internet"])

    Internet <-->|HTTP / HTTPS| IGW_A["Internet Gateway\nvpc-a-igw"]
    Internet <-->|HTTP / HTTPS| IGW_B["Internet Gateway\nvpc-b-igw"]

    subgraph VPC_A["VPC-A — 10.0.0.0/16"]
        subgraph PUB_A["Public Subnets"]
            PA1["10.0.1.0/24\nap-south-1a"]
            PA2["10.0.3.0/24\nap-south-1b"]
        end
        NAT["NAT Gateway\n+ Elastic IP"]
        subgraph PRIV_A["Private Subnets"]
            PRA1["10.0.2.0/24\nap-south-1a"]
            PRA2["10.0.4.0/24\nap-south-1b"]
        end
        IGW_A --> PUB_A
        PA1 --> NAT
        NAT -->|"outbound only\n(no inbound)"| PRIV_A
    end

    subgraph VPC_B["VPC-B — 192.168.0.0/16"]
        subgraph PUB_B["Public Subnet"]
            PB1["192.168.1.0/24\nap-south-1a"]
        end
        subgraph PRIV_B["Private Subnet"]
            PRB1["192.168.2.0/24\nap-south-1a"]
        end
        IGW_B --> PUB_B
    end

    VPC_A <-->|"VPC Peering\nroutes on both sides"| VPC_B
```

---

## Traffic Flows

### Public subnet — inbound + outbound via IGW

```mermaid
flowchart LR
    Internet(["🌐 Internet"])
    IGW["Internet Gateway"]
    RT["Public Route Table\n0.0.0.0/0 → IGW"]
    EC2["EC2\nPublic Subnet"]

    Internet <-->|"request / response"| IGW
    IGW <--> RT
    RT <--> EC2
```

### Private subnet — outbound only via NAT

```mermaid
flowchart LR
    EC2P["EC2\nPrivate Subnet"]
    RT["Private Route Table\n0.0.0.0/0 → NAT"]
    NAT["NAT Gateway\n(in public subnet)"]
    IGW["Internet Gateway"]
    Internet(["🌐 Internet"])

    EC2P -->|"outbound request"| RT
    RT --> NAT
    NAT --> IGW
    IGW -->|"response comes back\nto NAT, not EC2"| NAT
    NAT -->|"forwarded back"| EC2P
```

> NAT translates the private IP to its Elastic IP on the way out, and back on the way in. The internet never sees your private EC2 IP.

### VPC peering — private to private

```mermaid
flowchart LR
    EC2_A["EC2\nVPC-A Private\n10.0.2.x"]
    RT_A["VPC-A Private RT\n192.168.0.0/16 → Peer"]
    PEER{{"VPC Peering\nConnection"}}
    RT_B["VPC-B Private RT\n10.0.0.0/16 → Peer"]
    EC2_B["EC2\nVPC-B Private\n192.168.2.x"]

    EC2_A --> RT_A --> PEER --> RT_B --> EC2_B
```

> Peering alone is not enough — routes must be added on **both** route tables or traffic is dropped.

---

## Route Tables Explained

Think of a route table as a **traffic police officer's rulebook**. Every packet that wants to go somewhere asks the officer which road to take. The officer checks the rulebook top to bottom and always follows the **most specific address**.

```
"India"                    → too vague   (0.0.0.0/0)
"Mumbai"                   → less vague  (10.0.0.0/16)
"Mumbai, Andheri, Lane 5"  → very exact  (10.0.2.0/24)

Officer always follows the most exact address first.
```

---

### VPC-A Public Route Table
**Attached to:** `10.0.1.0/24` and `10.0.3.0/24`

```
┌─────────────────────────────────────────────────────┐
│           PUBLIC ROUTE TABLE — VPC-A                │
├──────────────────┬──────────────┬───────────────────┤
│ WHERE YOU        │ WHICH ROAD   │ PLAIN ENGLISH      │
│ WANT TO GO       │ TO TAKE      │                   │
├──────────────────┼──────────────┼───────────────────┤
│ 10.0.0.0/16      │ local        │ going to your own │
│                  │              │ city? deliver      │
│                  │              │ direct, no road   │
│                  │              │ needed            │
├──────────────────┼──────────────┼───────────────────┤
│ 192.168.0.0/16   │ peering      │ going to VPC-B?   │
│                  │ connection   │ use the secret    │
│                  │              │ tunnel between    │
│                  │              │ the two cities    │
├──────────────────┼──────────────┼───────────────────┤
│ 0.0.0.0/0        │ vpc-a-igw    │ going ANYWHERE    │
│                  │              │ else on earth?    │
│                  │              │ use the main      │
│                  │              │ highway (IGW)     │
│                  │              │ to internet       │
└──────────────────┴──────────────┴───────────────────┘
```

Real example:
```
EC2 at 10.0.1.55 wants to reach Google (8.8.8.8)

Is 8.8.8.8 inside 10.0.0.0/16?     NO
Is 8.8.8.8 inside 192.168.0.0/16?  NO
Is 8.8.8.8 inside 0.0.0.0/0?       YES ✅ → take IGW highway
```

---

### VPC-A Private Route Table
**Attached to:** `10.0.2.0/24` and `10.0.4.0/24`

```
┌─────────────────────────────────────────────────────┐
│           PRIVATE ROUTE TABLE — VPC-A               │
├──────────────────┬──────────────┬───────────────────┤
│ WHERE YOU        │ WHICH ROAD   │ PLAIN ENGLISH      │
│ WANT TO GO       │ TO TAKE      │                   │
├──────────────────┼──────────────┼───────────────────┤
│ 10.0.0.0/16      │ local        │ going to your own │
│                  │              │ city? deliver      │
│                  │              │ direct            │
├──────────────────┼──────────────┼───────────────────┤
│ 192.168.0.0/16   │ peering      │ going to VPC-B?   │
│                  │ connection   │ use the secret    │
│                  │              │ tunnel            │
├──────────────────┼──────────────┼───────────────────┤
│ 0.0.0.0/0        │ vpc-a-nat    │ going anywhere    │
│                  │              │ else? go to NAT   │
│                  │              │ bodyguard — he    │
│                  │              │ goes outside for  │
│                  │              │ you, you stay     │
│                  │              │ hidden inside     │
└──────────────────┴──────────────┴───────────────────┘
```

Real example:
```
EC2 at 10.0.2.55 wants to download a package

→ goes to NAT bodyguard
→ NAT uses its Elastic IP to talk to internet
→ reply comes back to NAT
→ NAT forwards it back to 10.0.2.55

Internet never sees 10.0.2.55 — only sees NAT's Elastic IP ✅
```

---

### VPC-B Public Route Table
**Attached to:** `192.168.1.0/24`

```
┌─────────────────────────────────────────────────────┐
│           PUBLIC ROUTE TABLE — VPC-B                │
├──────────────────┬──────────────┬───────────────────┤
│ WHERE YOU        │ WHICH ROAD   │ PLAIN ENGLISH      │
│ WANT TO GO       │ TO TAKE      │                   │
├──────────────────┼──────────────┼───────────────────┤
│ 192.168.0.0/16   │ local        │ going to your own │
│                  │              │ city? deliver      │
│                  │              │ direct            │
├──────────────────┼──────────────┼───────────────────┤
│ 10.0.0.0/16      │ peering      │ going to VPC-A?   │
│                  │ connection   │ use the secret    │
│                  │              │ tunnel            │
├──────────────────┼──────────────┼───────────────────┤
│ 0.0.0.0/0        │ vpc-b-igw    │ going anywhere    │
│                  │              │ else? use VPC-B's │
│                  │              │ own IGW highway   │
└──────────────────┴──────────────┴───────────────────┘
```

---

### VPC-B Private Route Table
**Attached to:** `192.168.2.0/24` — most restricted, no internet at all

```
┌─────────────────────────────────────────────────────┐
│           PRIVATE ROUTE TABLE — VPC-B               │
├──────────────────┬──────────────┬───────────────────┤
│ WHERE YOU        │ WHICH ROAD   │ PLAIN ENGLISH      │
│ WANT TO GO       │ TO TAKE      │                   │
├──────────────────┼──────────────┼───────────────────┤
│ 192.168.0.0/16   │ local        │ going to your own │
│                  │              │ city? deliver      │
│                  │              │ direct            │
├──────────────────┼──────────────┼───────────────────┤
│ 10.0.0.0/16      │ peering      │ going to VPC-A?   │
│                  │ connection   │ use the tunnel    │
├──────────────────┼──────────────┼───────────────────┤
│ 0.0.0.0/0        │ ❌ NO ROUTE  │ going to          │
│                  │              │ internet? BLOCKED │
│                  │              │ no NAT here —     │
│                  │              │ talk to VPC-A if  │
│                  │              │ you need internet │
└──────────────────┴──────────────┴───────────────────┘
```

---

### The big picture — all 4 route tables

```
                    INTERNET 🌐
                        |
              ┌─────────┴─────────┐
              |                   |
           IGW-A               IGW-B
              |                   |
    ┌─────────┴──────┐   ┌───────┴──────────┐
    |   VPC-A        |   |   VPC-B           |
    |                |   |                  |
    | PUBLIC         |   | PUBLIC           |
    | 10.0.1.0/24   |   | 192.168.1.0/24  |
    | 10.0.3.0/24   |   |   ↕ IGW          |
    |   ↕ IGW       |   |                  |
    |                |   |  (no NAT)        |
    |    NAT 🛡️      |   |                  |
    |     ↕          |   | PRIVATE          |
    | PRIVATE        |   | 192.168.2.0/24  |
    | 10.0.2.0/24   |   |   ❌ no internet  |
    | 10.0.4.0/24   |   |                  |
    └───────┬────────┘   └────────┬─────────┘
            |                    |
            └──── PEERING ───────┘
              both can talk to each other
```

---

### 3 rules to never forget

```
1. local route ALWAYS wins
   traffic inside the VPC never accidentally leaves

2. 0.0.0.0/0 is always last resort
   public subnet  → IGW  (direct internet)
   private subnet → NAT  (hidden internet)
   VPC-B private  → ❌   (no internet at all)

3. peering needs routes on BOTH sides
   VPC-A must know about 192.168.0.0/16 → peering
   VPC-B must know about 10.0.0.0/16   → peering
   one side missing = traffic dropped silently
```

---

## NACL vs Security Group

```mermaid
flowchart TB
    Internet(["🌐 Internet"])
    NACL["NACL\n❌ Stateless\nRules evaluated on EVERY packet\nInbound AND outbound rules required"]
    SG["Security Group\n✅ Stateful\nReturn traffic is automatic\nInbound rules only needed"]
    EC2["EC2 Instance"]

    Internet -->|"1. hits NACL first"| NACL
    NACL -->|"2. then hits SG"| SG
    SG -->|"3. reaches instance"| EC2
```

---

## State Management

```mermaid
flowchart LR
    Dev(["👨‍💻 Developer"])
    TF["terraform apply"]
    Lock["S3 .tflock file\nuse_lockfile = true"]
    S3["S3 Bucket\nterraform.tfstate"]
    AWS["☁️ AWS Resources"]

    Dev --> TF
    TF -->|"1. acquire lock"| Lock
    TF -->|"2. read current state"| S3
    TF -->|"3. create / update / destroy"| AWS
    TF -->|"4. write new state"| S3
    TF -->|"5. release lock"| Lock
```

> If two people run `terraform apply` at the same time, S3 native locking blocks the second one until the first finishes.

---

## Folder Map

```
terraform-aws-vpc-lab/
|
+-- [versions.tf]
|      required_version = ">= 1.10"
|      aws provider ~> 5.0
|      backend "s3" {
|        bucket       = "ACCOUNT_ID-network-lab-tfstate"
|        key          = "network-lab/terraform.tfstate"
|        region       = "ap-south-1"
|        encrypt      = true
|        use_lockfile = true
|      }
|
+-- [variables.tf]
|      var.aws_region   (default: "ap-south-1")
|      var.admin_cidr   (no default — must be set explicitly)
|      var.vpc_a        (cidr, public_subnets, private_subnets, azs)
|      var.vpc_b        (cidr, public_subnets, private_subnets, azs)
|      + validation blocks on every CIDR and subnet count
|
+-- [terraform.tfvars]
|      aws_region = "ap-south-1"
|      admin_cidr = "x.x.x.x/32"        <- your IP (curl ifconfig.me)
|      vpc_a = {
|        cidr            = "10.0.0.0/16"
|        public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
|        private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]
|        azs             = ["ap-south-1a", "ap-south-1b"]
|      }
|      vpc_b = {
|        cidr            = "192.168.0.0/16"
|        public_subnets  = ["192.168.1.0/24"]
|        private_subnets = ["192.168.2.0/24"]
|        azs             = ["ap-south-1a"]
|      }
|
+-- [main.tf]
|      provider "aws" { region = var.aws_region }
|      locals { common_tags = { Project, ManagedBy, Layer } }
|      calls 14 modules:
|        module.vpc_a            module.vpc_b
|        module.subnets_a        module.subnets_b
|        module.igw_a            module.igw_b
|        module.nat_a
|        module.vpc_peering
|        module.route_tables_a   module.route_tables_b
|        module.nacl_a           module.nacl_b
|        module.sg_a             module.sg_b
|
+-- [outputs.tf]
|      vpc_a_id                  vpc_b_id
|      vpc_a_public_subnet_ids   vpc_b_public_subnet_ids
|      vpc_a_private_subnet_ids  vpc_b_private_subnet_ids
|      peering_connection_id
|      nat_gateway_ip
|      vpc_a_web_sg_id           vpc_b_web_sg_id
|      vpc_a_private_sg_id       vpc_b_private_sg_id
|
+-- bootstrap/
|      aws_s3_bucket              "{account_id}-network-lab-tfstate"
|        versioning:  Enabled
|        encryption:  AES256
|        public_access: fully blocked
|        lifecycle:   expire noncurrent versions after 90 days
|      locking: use_lockfile = true (S3 native — no DynamoDB needed)
|
+-- modules/
       |
       +-- vpc/
       |     aws_vpc.this
       |     enable_dns_hostnames = true
       |     enable_dns_support   = true
       |
       +-- subnets/
       |     aws_subnet.public   (for_each keyed on CIDR string)
       |       map_public_ip_on_launch = true
       |     aws_subnet.private  (for_each keyed on CIDR string)
       |
       +-- internet_gateway/
       |     aws_internet_gateway.this
       |     attached to var.vpc_id
       |
       +-- nat_gateway/
       |     aws_eip.nat           domain = "vpc"
       |     aws_nat_gateway.this  placed in public_subnet_ids[0]
       |
       +-- route_tables/
       |     aws_route_table.public
       |       aws_route.public_igw      0.0.0.0/0  -> igw_id    (if set)
       |       aws_route.public_peering  peer_cidr  -> peer conn  (if set)
       |     aws_route_table.private
       |       aws_route.private_nat     0.0.0.0/0  -> nat_id    (if set)
       |       aws_route.private_peering peer_cidr  -> peer conn  (if set)
       |     aws_route_table_association for every subnet
       |
       +-- nacl/
       |     aws_network_acl.public   (stateless)
       |       INBOUND   100 tcp :80         allow 0.0.0.0/0
       |                 110 tcp :443        allow 0.0.0.0/0
       |                 120 tcp :22         allow admin_cidr
       |                 130 tcp :1024-65535 allow 0.0.0.0/0
       |       OUTBOUND  100 tcp :80         allow 0.0.0.0/0
       |                 110 tcp :443        allow 0.0.0.0/0
       |                 120 tcp :1024-65535 allow 0.0.0.0/0
       |     aws_network_acl.private  (stateless)
       |       INBOUND   100 tcp :0-65535    allow vpc_cidr
       |                 110 tcp :1024-65535 allow 0.0.0.0/0
       |       OUTBOUND  100 tcp :0-65535    allow vpc_cidr
       |                 110 tcp :443        allow 0.0.0.0/0
       |                 120 tcp :80         allow 0.0.0.0/0
       |
       +-- security_groups/
       |     aws_security_group.web      "{prefix}-web-sg"
       |       INBOUND   tcp :80   from 0.0.0.0/0
       |                 tcp :443  from 0.0.0.0/0
       |                 tcp :22   from admin_cidr
       |       OUTBOUND  all       to   0.0.0.0/0
       |     aws_security_group.private  "{prefix}-private-sg"
       |       INBOUND   all from web-sg (security_groups ref)
       |                 tcp :22  from vpc_cidr
       |       OUTBOUND  all to 0.0.0.0/0
       |
       +-- vpc_peering/
             aws_vpc_peering_connection.this
             vpc_id      = vpc_a_id  (requester)
             peer_vpc_id = vpc_b_id  (accepter)
             auto_accept = true      (same account + region only)
             name        = "vpc-a-to-vpc-b"
```

---

## Full Architecture Flowchart

```
+-----------------------------------------------+
|                  variables.tf                 |
|  var.aws_region  var.admin_cidr               |
|  var.vpc_a { cidr, subnets, azs }             |
|  var.vpc_b { cidr, subnets, azs }             |
+-----------------------------------------------+
                        |
                        v
+-----------------------------------------------+
|               terraform.tfvars                |
|  aws_region = "ap-south-1"                    |
|  admin_cidr = "x.x.x.x/32"                   |
|  vpc_a.cidr = "10.0.0.0/16"                  |
|  vpc_b.cidr = "192.168.0.0/16"               |
+-----------------------------------------------+
                        |
                        v
+-----------------------------------------------+
|                   main.tf                     |
|   provider "aws" { region = "ap-south-1" }    |
|   calls all 14 modules + wires outputs        |
+-----------------------------------------------+
          |                                |
          v                                v

+-----------------------+      +-----------------------+
|     module.vpc_a      |      |     module.vpc_b      |
|  aws_vpc.this         |      |  aws_vpc.this         |
|  cidr = 10.0.0.0/16  |      |  cidr = 192.168.0.0/16|
|  dns_hostnames = true |      |  dns_hostnames = true |
+-----------------------+      +-----------------------+
          |                                |
          v                                v
+-----------------------+      +-----------------------+
|   module.subnets_a    |      |   module.subnets_b    |
|  PUBLIC (for_each)    |      |  PUBLIC (for_each)    |
|   10.0.1.0/24  az1   |      |   192.168.1.0/24 az1  |
|   10.0.3.0/24  az2   |      |                       |
|  PRIVATE (for_each)   |      |  PRIVATE (for_each)   |
|   10.0.2.0/24  az1   |      |   192.168.2.0/24 az1  |
|   10.0.4.0/24  az2   |      |                       |
+-----------------------+      +-----------------------+
          |                                |
          v                                v
+-----------------------+      +-----------------------+
|     module.igw_a      |      |     module.igw_b      |
|  aws_internet_gateway |      |  aws_internet_gateway |
|  name = "vpc-a-igw"   |      |  name = "vpc-b-igw"   |
+-----------------------+      +-----------------------+
          |
          v
+-----------------------+
|     module.nat_a      |
|  aws_eip.nat          |
|    domain = "vpc"     |
|  aws_nat_gateway.this |
|    subnet = 10.0.1.0  |
|    (public_ids[0])    |
+-----------------------+

          |                                |
          +-------------+  +--------------+
                        |  |
                        v  v
          +-------------------------------+
          |       module.vpc_peering      |
          |  aws_vpc_peering_connection   |
          |  vpc_a_id  <-->  vpc_b_id     |
          |  auto_accept = true           |
          |  name = "vpc-a-to-vpc-b"      |
          +-------------------------------+
          |                                |
          v                                v
+-----------------------+      +-----------------------+
| module.route_tables_a |      | module.route_tables_b |
|  PUBLIC route table   |      |  PUBLIC route table   |
|   0.0.0.0/0 -> igw_a |      |   0.0.0.0/0 -> igw_b |
|   192.168.0.0/16->peer|      |   10.0.0.0/16  ->peer |
|  PRIVATE route table  |      |  PRIVATE route table  |
|   0.0.0.0/0 -> nat_a |      |   (no NAT gateway)    |
|   192.168.0.0/16->peer|      |   10.0.0.0/16  ->peer |
+-----------------------+      +-----------------------+
          |                                |
          v                                v
+-----------------------+      +-----------------------+
|     module.nacl_a     |      |     module.nacl_b     |
|  PUBLIC nacl          |      |  PUBLIC nacl          |
|   IN:  80,443,22,eph  |      |   IN:  80,443,22,eph  |
|   OUT: 80,443,eph     |      |   OUT: 80,443,eph     |
|  PRIVATE nacl         |      |  PRIVATE nacl         |
|   IN:  vpc_cidr,eph   |      |   IN:  vpc_cidr,eph   |
|   OUT: vpc_cidr,80,443|      |   OUT: vpc_cidr,80,443|
+-----------------------+      +-----------------------+
          |                                |
          v                                v
+-----------------------+      +-----------------------+
|      module.sg_a      |      |      module.sg_b      |
|  vpc-a-web-sg         |      |  vpc-b-web-sg         |
|   IN:  80,443,22      |      |   IN:  80,443,22      |
|   OUT: all            |      |   OUT: all            |
|  vpc-a-private-sg     |      |  vpc-b-private-sg     |
|   IN:  from web-sg    |      |   IN:  from web-sg    |
|        22/vpc_cidr    |      |        22/vpc_cidr    |
|   OUT: all            |      |   OUT: all            |
+-----------------------+      +-----------------------+
          |                                |
          +----------------+---------------+
                           |
                           v
          +---------------------------------------+
          |              outputs.tf               |
          |  vpc_a_id               vpc_b_id      |
          |  vpc_a_public_subnet_ids              |
          |  vpc_a_private_subnet_ids             |
          |  vpc_b_public_subnet_ids              |
          |  vpc_b_private_subnet_ids             |
          |  peering_connection_id                |
          |  nat_gateway_ip                       |
          |  vpc_a_web_sg_id  vpc_a_private_sg_id |
          |  vpc_b_web_sg_id  vpc_b_private_sg_id |
          +---------------------------------------+
```

---

## Why Bootstrap Exists

### The chicken and egg problem

Your `versions.tf` tells Terraform to store state in an S3 bucket.
But that bucket must exist **before** `terraform init` can run.

```
terraform init needs the S3 bucket to store state
          ↓
S3 bucket does not exist yet
          ↓
who creates the S3 bucket?
          ↓
Terraform can create it — but Terraform needs
the bucket first before it can run
          ↓
🐔 chicken needs egg
🥚 egg needs chicken
```

Bootstrap breaks this loop. It is a **separate tiny Terraform project**
that runs with local state (no S3 needed) and creates the bucket first.

```
STEP 1 — bootstrap runs with local state on your laptop
──────────────────────────────────────────────────────
cd bootstrap/
terraform init    ← no S3 needed, state stays locally
terraform apply   ← S3 bucket created ✅

STEP 2 — now S3 exists, main project can use it
──────────────────────────────────────────────────────
cd ..
terraform init    ← connects to S3 bucket ✅
terraform apply   ← builds your whole VPC lab
                     state stored safely in S3 ✅
```

---

### Why not just click and create the bucket in AWS console?

You could — but:

```
Manual console click              Bootstrap Terraform
────────────────────              ───────────────────
not repeatable                    run it again anytime
easy to forget settings           versioning, encryption,
  versioning, encryption,           public access block
  public access block               all in code
no record of what you did         git history shows everything
different settings every time     same result every time
```

---

### What bootstrap creates

```
aws_s3_bucket  →  {account_id}-network-lab-tfstate
      │
      ├── versioning        ON
      │     keeps every old state file
      │     roll back if something breaks
      │
      ├── encryption        AES256
      │     state file contains resource IDs
      │     must be kept private
      │
      ├── public access     FULLY BLOCKED
      │     nobody on internet can see your state
      │
      └── lifecycle rule    expire after 90 days
            stops S3 storage growing forever
```

No DynamoDB needed — S3 native locking handles it with `use_lockfile = true`.

---

### Run bootstrap only once

```
✅ Run when:    setting up this project for the first time

❌ Never again: the bucket already exists
                running twice will conflict

✅ After done:  delete bootstrap/terraform.tfstate from your laptop
                you do not need it — the bucket is already live
```

---

## Deployment

### Step 1 — create the backend infrastructure (run once)

```bash
cd bootstrap/
terraform init
terraform apply
# outputs: bucket name to paste into versions.tf
```

### Step 2 — configure the backend

Edit `versions.tf` and replace `ACCOUNT_ID` with your actual AWS account ID from the bootstrap output:

```hcl
backend "s3" {
  bucket       = "123456789012-network-lab-tfstate"
  key          = "network-lab/terraform.tfstate"
  region       = "ap-south-1"
  encrypt      = true
  use_lockfile = true
}
```

### Step 3 — set your admin IP

```bash
# Find your public IP
curl ifconfig.me
```

Update `terraform.tfvars`:
```hcl
admin_cidr = "203.0.113.5/32"   # your IP
```

### Step 4 — deploy

```bash
cd ..
terraform init      # connects to S3 backend
terraform plan      # preview what will be created
terraform apply     # build the lab
terraform output    # see all resource IDs
```

### Deployment flow

```mermaid
flowchart TD
    A([Start]) --> B[cd bootstrap/\nterraform init && apply]
    B --> C[Copy outputs into versions.tf]
    C --> D[Set admin_cidr in terraform.tfvars]
    D --> E[terraform init]
    E --> F[terraform plan]
    F --> G{Plan looks right?}
    G -->|No| H[Fix .tf files]
    H --> F
    G -->|Yes| I[terraform apply]
    I --> J[terraform output]
    J --> K([Lab running ✅])
```

---

## Learning Progression

Follow these steps in order — each one teaches a distinct concept:

| Step | What to do | Concept learned |
|------|-----------|-----------------|
| 1 | Apply VPC-A + IGW only | CIDR blocks, internet routing |
| 2 | Add NAT Gateway | Private subnet outbound, Elastic IP |
| 3 | Add NACLs | Stateless firewall, ephemeral ports |
| 4 | Add Security Groups | Stateful firewall, SG vs NACL difference |
| 5 | Apply VPC-B | Isolated network, no default connectivity |
| 6 | Add VPC Peering | Cross-VPC routing |
| 7 | Add peering routes on both sides | Why peering alone isn't enough |

---

## Key Commands

```bash
# Preview changes without applying
terraform plan

# Apply only a specific module
terraform apply -target=module.vpc_a

# See all outputs
terraform output

# Show current state
terraform state list

# Import an existing AWS resource into state
terraform import 'module.vpc_a.aws_vpc.this' vpc-0a1b2c3d

# Destroy everything (careful!)
terraform destroy
```

---

## Destroying the Lab

### Step 1 — disable prevent_destroy on VPCs

VPCs have `lifecycle { prevent_destroy = true }` which blocks `terraform destroy` by design.
You must comment it out first in `modules/vpc/main.tf`:

```hcl
# modules/vpc/main.tf

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })

  # lifecycle {       ← comment this out before destroying
  #   prevent_destroy = true
  # }
}
```

### Step 2 — destroy the VPC lab

```bash
terraform destroy
```

Terraform will destroy all 38 resources — VPCs, subnets, IGWs, NAT, NACLs, SGs, peering.

### Step 3 — re-enable prevent_destroy

Uncomment the lifecycle block back immediately after destroy:

```hcl
  lifecycle {
    prevent_destroy = true
  }
```

Then commit so the protection is back in git:

```bash
git add modules/vpc/main.tf
git commit -m "chore: re-enable prevent_destroy on VPCs after teardown"
```

---

### Destroying the bootstrap S3 bucket

The bootstrap bucket has **versioning enabled** — AWS will not let you delete a versioned
bucket that still has objects in it, even if you empty it normally.

You have two options:

**Option A — force_destroy via Terraform (recommended)**

Add `force_destroy = true` to `bootstrap/main.tf` before destroying:

```hcl
resource "aws_s3_bucket" "tfstate" {
  bucket        = local.bucket_name
  force_destroy = true    # ← add this line

  tags = { ... }
}
```

Then:

```bash
cd bootstrap/
terraform apply          # updates the bucket with force_destroy = true
terraform destroy        # now it can delete the bucket including all versions
```

**Option B — delete all versions manually via AWS CLI**

```bash
# delete all object versions
aws s3api delete-objects \
  --bucket 952933884165-network-lab-tfstate \
  --delete "$(aws s3api list-object-versions \
    --bucket 952933884165-network-lab-tfstate \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# then destroy
cd bootstrap/
terraform destroy
```

---

### Full teardown order

```
1. Comment out prevent_destroy in modules/vpc/main.tf
2. terraform destroy                    (destroys VPC lab)
3. Uncomment prevent_destroy back
4. cd bootstrap/
5. Add force_destroy = true to bucket
6. terraform apply
7. terraform destroy                    (destroys S3 bucket)
```

---

## Cost Estimate

| Resource | Cost |
|----------|------|
| NAT Gateway | ~$45/month + data transfer |
| Elastic IP (attached) | Free |
| VPC Peering (same region) | Free + $0.01/GB data transfer |
| IGW, Subnets, NACLs, SGs | Free |

> Destroy the lab when not in use to avoid NAT Gateway charges: `terraform destroy`
