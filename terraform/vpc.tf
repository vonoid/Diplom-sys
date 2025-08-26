resource "yandex_vpc_network" "diplom_vpc" {
  name = "diplom-vpc"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}
