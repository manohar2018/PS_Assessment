variable "awsprops" {
    type = "map"
    default = {
    region = "us-west-1"
    ami = "<<ami name>>"
    itype = "t2.micro"
    publicip = true
    keyname = "<<existing keypair name>>"
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
  type    = "list"
  default = ["us-west-1a", "us-west-1b"]
}

variable "web_server_count" {
  default = 2
}