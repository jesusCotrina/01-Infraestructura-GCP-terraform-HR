locals {
  env_vars = jsondecode(file("../env.json"))
  config_consolidado= jsondecode(file("../config/config_consolidado.json"))
}