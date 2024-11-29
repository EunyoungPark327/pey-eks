variable "vpc_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "env" {
  default = "dev"
}
variable "azs" {
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}
variable "cluster_name" {
  type = string
}
