provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.availability_zone
}

### network ###
resource "yandex_vpc_network" "k8s-default" {
  folder_id = var.folder_id
  name      = "k8s-default"
}

resource "yandex_vpc_subnet" "k8s-default" {
  name           = "k8s-default-${var.availability_zone}"
  zone           = var.availability_zone
  v4_cidr_blocks = ["192.168.0.0/16"]
  network_id     = yandex_vpc_network.k8s-default.id
}

### accounts ###
resource "yandex_iam_service_account" "k8s-resources" {
  folder_id = var.folder_id

  name        = "k8s-resources"
  description = "Service account for resource editing"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id

  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.k8s-resources.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id

  role   = "k8s.clusters.agent"
  member = "serviceAccount:${yandex_iam_service_account.k8s-resources.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-publicAdmin" {
  folder_id = var.folder_id

  role   = "vpc.publicAdmin"
  member = "serviceAccount:${yandex_iam_service_account.k8s-resources.id}"
}

resource "yandex_iam_service_account" "k8s-nodes" {
  folder_id = var.folder_id

  name        = "k8s-nodes"
  description = "Service account for pulling docker images"
}

resource "yandex_resourcemanager_folder_iam_member" "viewer" {
  folder_id = var.folder_id

  role   = "viewer"
  member = "serviceAccount:${yandex_iam_service_account.k8s-nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id

  role   = "container-registry.images.puller"
  member = "serviceAccount:${yandex_iam_service_account.k8s-nodes.id}"
}

### security ###
resource "yandex_kms_symmetric_key" "kms-key" {
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
}

resource "yandex_kms_symmetric_key_iam_binding" "viewer" {
  symmetric_key_id = yandex_kms_symmetric_key.kms-key.id
  role             = "viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-resources.id}",
  ]
}

### k8s-cluster ###
resource "yandex_kubernetes_cluster" "k8s-zonal" {
  name       = "k8s-zonal"
  network_id = yandex_vpc_network.k8s-default.id

  master {
    version = "1.23"

    zonal {
      zone      = yandex_vpc_subnet.k8s-default.zone
      subnet_id = yandex_vpc_subnet.k8s-default.id
    }

    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.k8s-resources.id
  node_service_account_id = yandex_iam_service_account.k8s-nodes.id


  depends_on = [
    yandex_resourcemanager_folder_iam_member.editor,
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-publicAdmin,

    yandex_resourcemanager_folder_iam_member.viewer,
    yandex_resourcemanager_folder_iam_member.images-puller
  ]
}

### nodes ###
resource "yandex_kubernetes_node_group" "k8s-node-group" {
  cluster_id = yandex_kubernetes_cluster.k8s-zonal.id
  name       = "k8s-node-group"
  version    = "1.23"

  labels = {
    "app" = "momo-store"
  }

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.k8s-default.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = var.availability_zone
    }
  }

  maintenance_policy {
    auto_upgrade = false
    auto_repair  = false
  }
}
