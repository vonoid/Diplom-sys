# Веб-сервер 1, зона A
resource "yandex_compute_instance" "web1" {
  name        = "web1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_a.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  hostname = "web1.ru-central1.internal"

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Веб-сервер 2, зона B
resource "yandex_compute_instance" "web2" {
  name        = "web2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_b.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  scheduling_policy {
    preemptible = true
  }

  hostname = "web2.ru-central1.internal"

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
