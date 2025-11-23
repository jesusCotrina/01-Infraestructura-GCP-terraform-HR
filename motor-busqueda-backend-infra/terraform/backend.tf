terraform {
  backend "gcs" {
    bucket = "rawzone-tf-backend-state-frmk-scrp" 
    prefix = "state/init"
    
  }
}