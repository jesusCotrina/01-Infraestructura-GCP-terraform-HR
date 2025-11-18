/*Es el unico valor estatico para cada entorno no se cambia*/
terraform {
  backend "gcs" {
    bucket = "rawzone-tf-backend-state-frmk-scrp" 
    prefix = "state/init"
    
  }
}

