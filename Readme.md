# 01-Infraestructura-GCP-terraform-HR

> Repositorio para gestionar la infraestructura en Google Cloud Platform (GCP) usando **Terraform**.  
> Organización por módulos/carpetas para administrar infra compartida y la infra específica de cada proyecto.

### `administrador-infra`
Infra base y recursos compartidos entre proyectos, por ejemplo:
- Service Accounts (cuentas para deploy y ejecución)
- Buckets (estado remoto, artefactos)
- Cloud Build triggers y permisos
- Roles y políticas IAM generales
- Recursos de red base (VPC, subnets, VPC Connector)

### `framework-scraping-infra`
Infra específica del proyecto de scraping:
- Cloud Run / Cloud Run jobs
- Cloud Scheduler
- Pub/Sub / Topics (si aplica)
- Secret Manager y variables por entorno
- Archivos JSON para parametrización por ambiente

### `motor-busqueda-backend-infra`
Infra del backend de búsqueda:
- Cloud Run (servicios)
- Artifact Registry (imágenes)
- IAM (invoker, roles específicos)
- Secret Manager (API keys, DB credentials)
- Configuración configurable vía JSON

---

## Principio de configuración

- Cada módulo usa archivos `.json` (o `env.json`, `config/*.json`) para parametrizar: proyecto, región, nombres, memoria, variables de entorno, repositorio de imágenes, etc.
- Esto permite reutilizar el mismo módulo para `dev`, `qa`, `prod` sin tocar el HCL.

Ejemplo mínimo de `config`:
```json
{
  "service_name": "motor-busqueda",
  "location": "us-east4",
  "memory": "2Gi",
  "repositorio": "backend-motor-busqueda",
  "env": {
    "DB_HOST": "db.example.com",
    "DB_USER": "user",
    "DB_PASSWORD": "secret"
  }
}
```

## Buenas prácticas recomendadas

### Estado remoto
Configurar backend GCS con locking para evitar colisiones.

### No versionar secretos
Usar Secret Manager y referenciar secrets desde Terraform.

### Imágenes
No usar :latest para despliegues; taggear con SHA ($SHORT_SHA) para reproducibilidad.

### Min/Max scale
Definir autoscaling.knative.dev/minScale cuando se requiera evitar cold starts.

### CPU en idle
run.googleapis.com/cpu-throttling = "false" si necesitas CPU fuera de request.

### Importar recursos existentes
Usar `terraform import` para recursos creados manualmente.

### Separar entornos
Usar workspaces, carpetas o variables por entorno.

---

## Autor
Jesús Cotrina – Infraestructura, automatización y despliegue en GCP