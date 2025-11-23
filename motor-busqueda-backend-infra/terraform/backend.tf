terraform {
  backend "gcs" {
    bucket = "raw-tf-backend-motor-busqueda" 
    prefix = "state/init"
    
  }
}