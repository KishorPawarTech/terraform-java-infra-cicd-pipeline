resource "aws_vpc" "custom_vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "three-tier-vpc"
    }
}

resource "aws_subnet" "pub_subnet"{
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "pub-subnet"
    }
}

resource "aws_subnet" "pvt_sub_frontend"{
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "pvt-subnet-frontend"
    }
}

resource "aws_subnet" "pvt_sub_backend"{
    cidr_block = "10.0.3.0/24"
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "pvt-subnet-backend"
    }
}

resource "aws_subnet" "pvt_sub_db_1"{
    cidr_block = "10.0.4.0/24"
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "pvt-subnet-db-1"
    }
}

resource "aws_subnet" "pvt_sub_db_2"{
    cidr_block = "10.0.5.0/24"
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "pvt-subnet-db-2"
    }
}

resource "aws_internet_gateway" "dev_igw"{
    vpc_id = aws_vpc.custom_vpc.id
    tags = {
        Name = "dev_igw"
    }
}

resource "aws_route_table" "pub_rt"{
    vpc_id = aws_vpc.custom_vpc.id
    route {

        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.dev_igw.id
    }
    tags = {
        Name = "pub-rt"
    }
}

resource "aws_route_table_association" "pub_rt_assoc"{
    subnet_id = aws_subnet.pub_subnet.vpc_id
    route_table_id = aws_route_table.pub_rt.id
}

resource "aws_nat_gateway" "nat_gateway"{
    vpc_id = aws_vpc.custom_vpc.id
    availability_mode = "regional"  
    connectivity_type = "public"
    subnet_id = aws_subnet.pub_subnet.id
    tags = {
        Name = "nat-gateway"
    }
}

resource "aws_route_table" "pvt_rt"{
    vpc_id = aws_vpc.custom_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gateway.id
    }
    tags = {
        Name = "pvt-rt"
    }
}

resource "aws_route_table_association" "pvt_rt_assoc" {

    for_each = {
        pvt_sub_frontend = aws_subnet.pvt_sub_frontend.id
        pvt_sub_backend  = aws_subnet.pvt_sub_backend.id
        pvt_sub_db_1     = aws_subnet.pvt_sub_db_1.id
        pvt_sub_db_2     = aws_subnet.pvt_sub_db_2.id
    }

    subnet_id      = each.value
    route_table_id = aws_route_table.pvt_rt.id
}

resource "aws_instance" "pub_instance" {
    ami           = "ami-0c230065b91270bc6"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.pub_subnet.id
    tags = {
        Name = "pub-instance"
    }
  
}

resource "aws_instance" "pvt_frontend_instance" {
    ami           = "ami-0c230065b91270bc6"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.pvt_sub_frontend.id
    tags = {
        Name = "pvt-instance"
    }
  
}

resource "aws_instance" "pvt_backend_instance" {
    ami           = "ami-0c230065b91270bc6"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.pvt_sub_backend.id
    tags = {
        Name = "pvt-instance"
    }
  
}

resource "aws_db_subnet_group" "pvt_db_subnet_group" {
  name = "pvt-db-subnet-group"

  subnet_ids = [
    aws_subnet.pvt_sub_db_1.id,
    aws_subnet.pvt_sub_db_2.id
  ]

  tags = {
    Name = "pvt-db-subnet-group"
  }
}

resource "aws_db_instance" "pvt_db_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  identifier           = "db-instance"
  username             = "admin"
  password             = "Kish123456"
  parameter_group_name = "8.0"
  backup_retention_period = 7
  skip_final_snapshot = false
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.pvt_db_subnet_group.name
}