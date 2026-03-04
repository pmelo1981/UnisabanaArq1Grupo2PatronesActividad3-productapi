# Product API - Microservicio REST

API REST para gestión de productos con despliegue automatizado en Kubernetes/AKS, Helm, ArgoCD y CI/CD.

## 🚀 Tecnologías

- **.NET 10** - Framework
- **Docker** - Containerización (multietapa)
- **Kubernetes/AKS** - Orquestación
- **Helm 3** - Gestión de configuración
- **NGINX Ingress Controller** - Enrutamiento HTTP(S)
- **ArgoCD** - GitOps automático
- **GitHub Actions** - CI/CD (Build → Test → Docker Push → Auto-deploy)
- **Azure Container Registry** - Registry privado de imágenes

---

## 📡 API REST - 7 Endpoints

```
GET    /api/products              # Obtener todos los productos
GET    /api/products/{id}         # Obtener por ID
GET    /api/products/stats        # Estadísticas (total, promedio, máximo, mínimo)
POST   /api/products              # Crear nuevo producto
PUT    /api/products/{id}         # Actualizar producto
DELETE /api/products/{id}         # Eliminar producto
GET    /api/products/health       # Health check
```

---

## 🎯 Descripción

Microservicio simple en ASP.NET Core 10 que expone una API REST para gestionar productos.

- ✅ 7 endpoints REST (CRUD + stats + health)
- ✅ 14 tests unitarios (xUnit)
- ✅ Dockerfile multistage (~150MB)
- ✅ Helm Charts con values.yaml + values-acr.yaml
- ✅ GitHub Actions CI/CD (ACR push automático)
- ✅ Despliega automáticamente en AKS vía ArgoCD

---

## 📂 Estructura

```
src/
├── ProductAPI/
│   ├── Program.cs                      # Entry point, DI, Swagger
│   ├── Controllers/ProductsController.cs    # 7 endpoints REST
│   ├── Models/Product.cs               # Domain model
│   └── Repositories/ProductRepository.cs    # In-memory storage
└── ProductAPI.Tests/
    └── ProductsControllerTests.cs      # 14 tests (xUnit)

docker/
└── Dockerfile                          # Multistage: sdk → aspnet runtime

helm/
├── Chart.yaml
├── values.yaml                         # Default values
├── values-acr.yaml                     # ACR overrides (image tag versionado)
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml                        # Horizontal Pod Autoscaler
    └── ingress.yaml                    # NGINX Ingress

.github/workflows/
└── ci-cd.yml                           # Build → Test → Docker Push ACR → Update tag → Push

azure/
├── setup-argocd.ps1                    # Install ArgoCD + apply manifests
├── create-aks-cluster.ps1              # Crear cluster
├── setup-acr-and-deploy.ps1            # Setup ACR
├── verify-deploy.ps1                   # Verificar despliegue
└── delete-all-resources.ps1            # Limpiar (muy importante)

README.md                               # Este archivo
```

---

## 🚀 Quick Start

### Tests

```bash
dotnet test
# Output: 14 passed ✅
```

### Ejecución Local

```bash
dotnet run --project src/ProductAPI/ProductAPI.csproj
# Swagger: http://localhost:5000/swagger
```

### Docker Local

```bash
docker build -f docker/Dockerfile -t productapi:local .
docker run -p 8080:8080 productapi:local
# Probar: curl http://localhost:8080/api/products/health
```

---

## 📊 API Endpoints Detallados

| Método | Endpoint | Body | Descripción |
|--------|----------|------|------------|
| GET | `/api/products` | - | Lista todos los productos |
| GET | `/api/products/{id}` | - | Obtiene producto por ID |
| GET | `/api/products/stats` | - | Estadísticas: total, promedio, máximo, mínimo |
| POST | `/api/products` | `{name, description, price}` | Crear nuevo |
| PUT | `/api/products/{id}` | `{name, description, price}` | Actualizar |
| DELETE | `/api/products/{id}` | - | Eliminar |
| GET | `/api/products/health` | - | Status de salud |

**Ejemplo de respuesta `/stats`:**
```json
{
  "total": 5,
  "promedio": 299.99,
  "maximo": 999.99,
  "minimo": 9.99
}
```

---

## 🔄 CI/CD Pipeline (GitHub Actions)

El pipeline se dispara automáticamente al hacer `git push` en `main`:

```
1. Checkout código
2. Setup .NET 10
3. dotnet restore (NuGet)
4. dotnet build -c Release
5. dotnet test (14 tests)
6. Login a Azure Container Registry
7. docker build -f docker/Dockerfile
8. docker push → ACR (tag: git SHA + latest)
9. sed actualiza values-acr.yaml con nuevo tag
10. git push automático
    ↓
    ArgoCD detecta (cada 3 min)
    ↓
    helm upgrade en Kubernetes
    ↓
    Rolling update (zero-downtime)
```

**No necesitas Docker Desktop.** Todo se construye en runners de GitHub en la nube.

---

## 🌐 GitOps Workflow

```
ProductAPI Repo (main branch)
    ↓
git push
    ↓
GitHub Actions: Build → Test → Docker Push a ACR
    ↓
Actualiza helm/values-acr.yaml con nueva imagen
    ↓
ArgoCD detecta el cambio (~3 minutos)
    ↓
kubectl apply de Helm charts
    ↓
Deployment actualizado automáticamente en AKS ✅
```

**Infraestructura (ArgoCD, Helm, K8s config):**  
👉 https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure

---

## ⚙️ Despliegue Manual en Kubernetes

```bash
# Usar valores desde ProductAPI repo
helm upgrade --install productapi ./helm \
  --namespace productapi \
  --create-namespace \
  -f helm/values-acr.yaml
```

---

## 🔐 Secretos Necesarios (GitHub)

Para que el CI/CD funcione, agrega estos **Repository Secrets** en:  
https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-productapi/settings/secrets/actions

| Secret | Ejemplo |
|--------|---------|
| `ACR_USERNAME` | `productapiregistry163505` |
| `ACR_PASSWORD` | `(access key del ACR)` |

---

## 📚 Documentación Adicional

- **Infrastructure Repo**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure
- **Personal Repo**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Helm Docs](https://helm.sh/docs/)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/)

---

## ⚠️ Importante: Limpieza

**Cuando termines el assignment, elimina TODOS los recursos** para evitar cargos:

```bash
az group delete --name productapi-rg --yes
```

Esto borra: AKS, ACR, Load Balancer, Storage, todo. (~$40/mes si no lo haces)

---

**Estado:** ✅ Producción-Ready  
**Última actualización:** 2024  
**Licencia:** MIT
