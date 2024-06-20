# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "backend" {
  default = ""
}

# bastion
variable "bastion" {
  type = object({
    machine_type = string
    disk_type    = string
    disk_size_gb = number
    tags         = list(string)
  })
}

variable "startup_script" {
  default = <<EOF
    #!/bin/bash
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
    apt update -y
    apt install -y wget ca-certificates mariadb-client-10.5 postgresql-client
  EOF
}
