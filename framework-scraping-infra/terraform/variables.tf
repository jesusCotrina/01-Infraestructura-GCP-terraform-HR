locals {
  env_vars = jsondecode(file("../env.json"))
  artifact_registry = jsondecode(file("../config/artifact_registry.json"))
}