# Security Group для бастиона
resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for bastion host"

  ingress {
    description = "SSH"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для веб-серверов
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for web servers"

  ingress {
    description = "HTTP from load balancer"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть где балансировщик
  }

  ingress {
    description = "SSH from bastion"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть где бастион
  }

  egress {
    description = "Outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для балансировщика
resource "yandex_vpc_security_group" "lb_sg" {
  name        = "load-balancer-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for load balancer"

  ingress {
    description = "HTTP"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outgoing traffic to web servers"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["10.0.2.0/24", "10.0.3.0/24"]  # Приватные подсети веб-серверов
  }
}

# Security Group для Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name        = "zabbix-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for Zabbix"

  ingress {
    description = "HTTP"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Zabbix agent"
    protocol    = "TCP"
    port        = 10050
    v4_cidr_blocks = ["10.0.0.0/8"]  # Вся внутренняя сеть
  }

  ingress {
    description = "Zabbix trapper"
    protocol    = "TCP"
    port        = 10051
    v4_cidr_blocks = ["10.0.0.0/8"]  # Вся внутренняя сеть
  }

  ingress {
    description = "SSH from bastion"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть
  }

  egress {
    description = "Outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for Elasticsearch"

  ingress {
    description = "Elasticsearch from Kibana"
    protocol    = "TCP"
    port        = 9200
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть где Kibana
  }

  ingress {
    description = "SSH from bastion"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть
  }

  egress {
    description = "Outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-security-group"
  network_id  = yandex_vpc_network.diplom_vpc.id
  description = "Security group for Kibana"

  ingress {
    description = "Kibana web interface"
    protocol    = "TCP"
    port        = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from bastion"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Публичная подсеть
  }

  egress {
    description = "Outgoing traffic to Elasticsearch"
    protocol    = "TCP"
    port        = 9200
    v4_cidr_blocks = ["10.0.2.0/24"]  # Приватная подсеть Elasticsearch
  }

  egress {
    description = "General outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
