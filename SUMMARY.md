# RESUMEN DE TRABAJO COMPLETADO

## Proyecto: Product API - Microservicio con Despliegue en Kubernetes (Azure AKS)

### Componentes del Proyecto

#### Microservicio .NET 10
- **API REST** con 5 endpoints CRUD + health check
  - `GET /api/products` - Listar productos
  - `GET /api/products/{id}` - Obtener por ID
  - `POST /api/products` - Crear producto
  - `PUT /api/products/{id}` - Actualizar producto
  - `DELETE /api/products/{id}` - Eliminar producto
  - `GET /api/products/health` - Health check
- **Repository Pattern** con almacenamiento en memoria
- **14 Pruebas Unitarias** (xUnit + Moq) - Todas pasando
- **OpenAPI** integrado (`MapOpenApi()` en desarrollo)

#### Contenedorizacion
- Dockerfile multietapa (SDK build -> runtime) - Solo HTTP puerto 8080
- `.dockerignore` para optimizar contexto de build
- Build con `--provenance=false --sbom=false` (evita manifests de attestation corruptos)

#### Kubernetes + Helm
- Helm Chart con templates: Deployment, Service (ClusterIP), Ingress, HPA
- NGINX Ingress Controller con DNS de Azure
- Auto-scaling horizontal (2-5 replicas)
- Acceso directo por IP y URL de Azure

#### CI/CD y GitOps
- **GitHub Actions** Pipeline (build, test, Docker build/push) - ✅ Verificado
- **ArgoCD** instalado y configurado - ✅ Synced + Healthy
  - Dashboard: `https://productapi-argocd.centralus.cloudapp.azure.com`
  - Sincronizacion automatica desde Git (auto-sync + self-heal)

### Scripts de Despliegue

3 scripts PowerShell para desplegar desde cero:

| Script | Funcion | Tiempo |
|--------|---------|--------|
| `.\azure\delete-all-resources.ps1` | Eliminar recursos existentes | ~5 min |
| `.\azure\create-aks-cluster.ps1` | Crear cluster AKS + NGINX Ingress + DNS | ~10 min |
| `.\azure\setup-acr-and-deploy.ps1` | Crear ACR, build imagen, deploy con Helm | ~8 min |

### Infraestructura Azure

| Recurso | Configuracion |
|---------|---------------|
| AKS Cluster | 1 nodo Standard_D2s_v3 (x86-64, 2 vCPU, 8GB RAM) |
| ACR | Basic SKU, nombre generado dinamicamente |
| Ingress | NGINX Controller v1.9.4 con DNS label de Azure |
| ArgoCD | LoadBalancer con DNS label `productapi-argocd` |
| Region | centralus |
| Suscripcion | Azure for Students |

### URLs de Acceso

Despues del despliegue quedan accesibles:

| Servicio | URL |
|----------|-----|
| API Health | `http://productapi.centralus.cloudapp.azure.com/api/products/health` |
| API Products | `http://productapi.centralus.cloudapp.azure.com/api/products` |
| ArgoCD Dashboard | `https://productapi-argocd.centralus.cloudapp.azure.com` |

### Estructura del Repositorio

```
src/ProductAPI/              Codigo fuente del microservicio
src/ProductAPI.Tests/        Pruebas unitarias (14 tests)
docker/Dockerfile            Imagen Docker multietapa
helm/                        Helm Chart (deployment, service, ingress, hpa)
azure/                       3 scripts PowerShell de despliegue
argocd/                      Manifests de ArgoCD
.github/workflows/           Pipeline CI/CD
.dockerignore                Exclusiones para Docker build
```

### Problemas Resueltos Durante el Despliegue

| Problema | Causa | Solucion |
|----------|-------|----------|
| exec format error en pods | VM ARM64 (Standard_B2ps_v2) | Cambiar a Standard_D2s_v3 (x86-64) |
| Imagen con architecture "unknown" | Docker Buildx attestation manifests | `--provenance=false --sbom=false` |
| TypeLoadException al iniciar | Swashbuckle 6.5.0 incompatible con .NET 10 | Remover paquete, usar MapOpenApi() |
| CrashLoopBackOff por certificado | HTTPS configurado sin certificado | Solo HTTP puerto 8080 |
| Ingress no rutea trafico | Annotation `kubernetes.io/ingress.class` deprecada | `ingressClassName: nginx` en spec |
| ACR login server con \r | PowerShell agrega retorno de carro | `-replace` con `Trim()` |
| Standard_B2s no disponible | No existe en suscripcion estudiante | Standard_D2s_v3 |
