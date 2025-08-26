# Target Group для Application Load Balancer
resource "yandex_alb_target_group" "web-tg" {
  name      = "web-target-group"
  
  target {
    subnet_id = yandex_vpc_subnet.private_a.id
    ip_address   = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.private_b.id
    ip_address   = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

# Backend Group для ALB
resource "yandex_alb_backend_group" "web-bg" {
  name      = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web-tg.id]
    
    healthcheck {
      timeout                = "2s"
      interval               = "5s"
      healthy_threshold      = 2
      unhealthy_threshold    = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "web-router" {
  name = "web-http-router-diplom"
}

# Virtual Host и Route
resource "yandex_alb_virtual_host" "web-vhost" {
  name           = "web-virtual-host-diplom"
  http_router_id = yandex_alb_http_router.web-router.id

  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-bg.id
        timeout          = "3s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "web-alb" {
  name        = "web-app-load-balancer-diplom"
  network_id  = yandex_vpc_network.diplom_vpc.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}

output "load_balancer_ip" {
  value = yandex_alb_load_balancer.web-alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "target_group_id" {
  value = yandex_alb_target_group.web-tg.id
}

output "backend_group_id" {
  value = yandex_alb_backend_group.web-bg.id
}

output "http_router_id" {
  value = yandex_alb_http_router.web-router.id
}
