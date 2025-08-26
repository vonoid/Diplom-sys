terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.80"
    }
  }
}

provider "yandex" {
  service_account_key_file = "${path.module}/../key.json"
  cloud_id                 = "b1gn4kthd37af87gp2vg"
  folder_id                = "b1ghft6dsjqpbsq8lid4"
  zone                     = "ru-central1-a"
}
