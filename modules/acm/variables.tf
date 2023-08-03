variable "tags" {
  type = map(string)
  default = {
    env = "Dev"
  }
}

variable "domain_name" {
  default = "example.com"
}
