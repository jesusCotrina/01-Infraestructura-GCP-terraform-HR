/*Es el unico valor estatico para cada entorno no se cambia*/
terraform {
  backend "gcs" {
    bucket = "artifacts-development-tf-state" 
    prefix = "state/init"
  }
}

