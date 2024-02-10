variable "name" {
  type        = string
  nullable    = false
  description = "Distribution name"
}

variable "single_page_app" {
  type = object({
    home_page = string
  })
  nullable    = true
  description = "If set, installs request handlers for single-page apps"
}

variable "domain" {
  type        = string
  nullable    = false
  description = "Domain name to map this distribution to"
}

variable "certificate_domain" {
  type        = string
  default     = null
  nullable    = true
  description = "Domain name of the certificate to use (default is '*' + var.domain)"
}

variable "origin" {
  type = object({
    s3 = object({
      bucket                      = string
      bucket_regional_domain_name = string
    })
    path = optional(string)
  })
  nullable    = false
  description = "S3 data or resource"
}

variable "default_document" {
  type        = string
  nullable    = true
  default     = null
  description = "Default document. Mutually exclusive with single_page_app."
}
