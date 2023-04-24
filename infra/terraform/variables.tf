variable "cloud_id" {
  type        = string
  description = "Cloud id where resources should be created (for provider conf)"
  sensitive   = true
  nullable    = false
}

variable "folder_id" {
  type        = string
  description = "Folder id where resources should be created (for provider conf)"
  sensitive   = true
  nullable    = false
}

variable "availability_zone" {
  default     = "ru-central1-a"
  type        = string
  description = "Availability zone"
  validation {
    condition     = contains(toset(["ru-central1-a", "ru-central1-b", "ru-central1-c"]), var.availability_zone)
    error_message = "Select availability zone from the list: ru-central1-a, ru-central1-b, ru-central1-c."
  }
  sensitive = true
  nullable  = false
}