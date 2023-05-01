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
      memory = 4
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

### s3 ###
// Create SA
resource "yandex_iam_service_account" "s3-sa" {
  folder_id = var.folder_id
  name      = "s3-sa"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.s3-sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.s3-sa.id
  description        = "static access key for object storage"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "momo-store-std-011-009" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket     = "momo-store-std-011-009"
  acl        = "public-read"
  max_size   = 1073741824
}

// Momo images
resource "yandex_storage_object" "momo-img-1" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-1"
  source       = "../data/4bdaeab0ee1842dc888d87d4a435afdd.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-2" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-2"
  source       = "../data/8b50f76f514a4ccaaacdcb832a1b3a2f.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-3" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-3"
  source       = "../data/8dee5a92281746aa887d6f19cf9fdcc7.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-4" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-4"
  source       = "../data/32cc88a33c3243a6a8838c034878c564.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-5" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-5"
  source       = "../data/50b583271fa0409fb3d8ffc5872e99bb.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-6" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-6"
  source       = "../data/788c073d83c14b3fa00675306dfb32b5.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-7" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-7"
  source       = "../data/7685ad7e9e634a58a4c29120ac5a5ee1.jpg"
  content_type = "image/jpeg"
}

resource "yandex_storage_object" "momo-img-8" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  bucket       = yandex_storage_bucket.momo-store-std-011-009.bucket
  acl          = "public-read"
  key          = "momo-img-8"
  source       = "../data/f64dcea998e34278a0006e0a2b104710.jpg"
  content_type = "image/jpeg"
}