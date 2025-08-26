# Приватная подсеть A
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

# Приватная подсеть B
resource "yandex_vpc_subnet" "private_b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom_vpc.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}
