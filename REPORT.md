# DevOps Capstone — Reporte Final

## 1. Resumen del proyecto

Proyecto integrador del bootcamp DevOps. Se implementaron prácticas de contenedores, Kubernetes, infraestructura como código, CI/CD, observabilidad y seguridad.

## 2. Arquitectura e implementación

### Contenedores y aplicación
- Aplicación Flask integrada con Amazon S3.
- Docker para construir y ejecutar imágenes.
- Docker Compose.
- Métricas Prometheus mediante prometheus_flask_exporter.

### Kubernetes
- K3s como distribución de Kubernetes.
- Despliegues mediante manifiestos.
- Helm para gestionar aplicaciones.
- Configuración de servicios y deployments.

### AWS e infraestructura como código
- AWS CLI e IAM.
- VPC, subredes públicas y privadas, Internet Gateway y NAT Gateway.
- Security Groups y tablas de rutas.
- Terraform para aprovisionamiento y destrucción de infraestructura.
- Amazon ECS Fargate.
- Amazon ECR.
- Application Load Balancer.
- Amazon S3.
- Amazon CloudFront con Origin Access Control.

Nota: Aurora Serverless se investigó y configuró en Terraform, pero AWS rechazó su creación por restricciones de la cuenta. No se considera un servicio desplegado.

### CI/CD
- GitHub Actions para integración continua.
- Construcción y publicación de imágenes Docker.
- Autenticación AWS mediante OIDC.
- Despliegue automatizado en ECS mediante Terraform.
- Prueba de actualización de aplicación con versión 2.0-cicd-test.

### Observabilidad y seguridad
- Prometheus y Grafana.
- Alertas de aplicación.
- Trivy para análisis de vulnerabilidades de imágenes.
- CloudWatch para logs de ECS.
- Container Insights habilitado en el clúster durante el despliegue.

## 3. Control de costos y limpieza

- Presupuesto AWS: USD 5 mensuales.
- Alerta de presupuesto al 80%.
- Teardown de 28 recursos Terraform.
- Estado remoto de Terraform vacío después de la destrucción.
- Sin NAT Gateways activos.
- Sin repositorios ECR en us-east-1.
- Sin clústeres ECS ni Load Balancers del capstone.
- Sin snapshots de clústeres RDS.

Buckets S3 conservados:
- bootcamp-capstone-7d6f8470
- devops-capstone-tfstate-181259113150-2026

## 4. Well-Architected Self-Review

| Pilar | Implementación |
|---|---|
| Operational Excellence | Terraform, GitHub Actions y automatización CI/CD |
| Security | IAM, OIDC, Security Groups, Trivy y CloudFront OAC |
| Reliability | Health checks, ECS y despliegue automatizado |
| Performance Efficiency | Docker, Kubernetes y ECS Fargate |
| Cost Optimization | Presupuesto AWS, control de recursos y teardown |
| Sustainability | Eliminación de infraestructura cuando no se utiliza |

## 5. Resultado de la prueba final

- GitHub Actions: ejecución exitosa.
- Autenticación OIDC: exitosa.
- Imagen Docker publicada en ECR.
- ECS: una tarea en ejecución.
- ALB: respuesta HTTP 200 OK.
- S3: conexión confirmada.
- Versión 2.0-cicd-test comprobada desde Internet.
- Teardown: 28 recursos destruidos correctamente.

## 6. Costos y horas de práctica

- Horas de práctica: pendiente de calcular.
- Costo total aproximado: pendiente de consultar en AWS Billing.
- Créditos restantes: pendiente de consultar.

## 7. Lecciones aprendidas

1. Automatizar infraestructura y despliegues mediante Terraform y GitHub Actions.
2. Integrar servicios AWS utilizando IAM, OIDC, ECS, ECR y S3.
3. Verificar aplicaciones mediante métricas, logs, health checks y pruebas funcionales.
4. Controlar costos y eliminar infraestructura que ya no se utiliza.
5. Documentar los procesos y mantener un repositorio de código organizado.

## 8. Conclusión

Se completó el proyecto integrador DevOps, desde la construcción de aplicaciones y contenedores hasta el despliegue automatizado en AWS, la observabilidad, la seguridad y la limpieza final de infraestructura.

El repositorio DevOps-labs conserva los laboratorios y evidencias del proceso de aprendizaje.
