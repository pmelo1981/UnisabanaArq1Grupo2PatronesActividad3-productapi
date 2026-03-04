# Product API - Microservicio REST

API REST para gestión de productos con despliegue automatizado en Kubernetes/AKS, Helm, ArgoCD y CI/CD.

## 🚀 Tecnologías

- **.NET 10** - Framework
- **Docker** - Containerización (multietapa)
- **Kubernetes/AKS** - Orquestación
- **Helm 3** - Gestión de configuración
- **NGINX Ingress Controller** - Enrutamiento HTTP(S)
- **ArgoCD** - GitOps automático
- **GitHub Actions** - CI/CD
- **Azure Container Registry** - Registry de imágenes

## 📡 API REST

```
GET    /api/products              # Obtener todos
GET    /api/products/{id}         # Obtener por ID
GET    /api/products/stats        # Estadísticas (total, promedio, max, min)
POST   /api/products              # Crear
PUT    /api/products/{id}         # Actualizar
DELETE /api/products/{id}         # Eliminar
GET    /api/products/health       # Health check
```

## 📚 Documentación

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitectura y patrones
- [GETTING_STARTED.md](docs/GETTING_STARTED.md) - Inicio local
- [TESTING.md](docs/TESTING.md) - Pruebas unitarias y Swagger
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Paso a paso manual
- [azure/README.md](azure/README.md) - Información de Azure

---

# 📦 ProductAPI Repository

**API REST de productos en .NET 10 con Kubernetes, Helm, CI/CD y GitOps.**

---

## 🎯 Descripción

Microservicio simple en ASP.NET Core 10 que expone una API REST para gestionar productos.

- ✅ 7 endpoints REST (CRUD + stats + health)
- ✅ 15 tests unitarios (xUnit)
- ✅ Dockerfile multistage
- ✅ Helm Charts
- ✅ GitHub Actions CI/CD
- ✅ Despliega automáticamente en AKS vía ArgoCD

---

## 📂 Estructura

```
src/
├── ProductAPI/
│   ├── Program.cs                    # Entry point, DI, Swagger
│   ├── Controllers/ProductsController.cs   # 6 endpoints REST
│   ├── Models/Product.cs             # Domain model
│   └── Repositories/ProductRepository.cs   # In-memory storage
└── ProductAPI.Tests/
    ├── ProductRepositoryTests.cs     # 7 tests
    └── ProductsControllerTests.cs    # 8 tests

docker/
└── Dockerfile                        # Multistage: build → runtime

helm/
├── Chart.yaml, values.yaml, values-acr.yaml
└── templates/ (deployment, service, hpa, ingress)

.github/workflows/ci-cd.yml           # Build → Test → ACR Push → Auto-deploy
azure/                                # PowerShell scripts para Azure
```

---

## 🚀 Quick Start

### Tests

```bash
dotnet test  # 15 tests passing ✅
```

### Local Execution

```bash
dotnet run --project src/ProductAPI/ProductAPI.csproj
# Swagger: http://localhost:5000/swagger
```

### Docker Local

```bash
docker build -f docker/Dockerfile -t productapi:local .
docker run -p 8080:8080 productapi:local
```

---

## 📡 API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|------------|
| GET | `/api/products` | Todos los productos |
| GET | `/api/products/{id}` | Producto por ID |
| POST | `/api/products` | Crear producto |
| PUT | `/api/products/{id}` | Actualizar producto |
| DELETE | `/api/products/{id}` | Eliminar producto |
| GET | `/api/products/health` | Health check |

---

## 🌐 GitOps Workflow

```
Código pusheado
    ↓
GitHub Actions: build → test → docker push
    ↓
values-acr.yaml actualizado automáticamente
    ↓
ArgoCD detecta cambio (cada 3 min)
    ↓
helm upgrade en Kubernetes
    ↓
Deployment automático ✅
```

**Ver Infraestructura**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure

---

## ⚙️ Deployment Kubernetes

```bash
# Helm deploy
helm upgrade --install productapi ./helm \
  --namespace productapi --create-namespace \
  --set image.repository=REGISTRY/productapi \
  --set image.tag=v1.0.0
```

---

## 📚 Más info

- [Infrastructure Repo](https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure) - GitOps Central
- [Personal Repo](https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3) - Referencia completa

**Estado:** ✅ Producción-Ready
