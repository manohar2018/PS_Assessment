variable "awsprops" {
    type = map
    default = {
    region = "us-east-2"
    ami = "ami-0e472ba40eb589f49"
    itype = "t2.micro"
    publicip = true
    keyname = "demo"
  }
}

variable "pub-sg"{
    default="pub-demo-sg"
}

variable "db-sg"{
    default="db-demo-sg"
}

variable "cidr" {
    default="10.1.0.0/16"
}

variable "azs" {
  type    = list
  default = ["us-east-2a", "us-east-2b"]
}

variable "web_server_count" {
  default = 2
}