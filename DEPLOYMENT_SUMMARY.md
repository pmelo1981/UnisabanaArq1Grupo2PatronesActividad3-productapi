# 🚀 DEPLOYMENT SUMMARY - Trabajo K8S

**Status**: ✅ **DEPLOYMENT COMPLETO Y FUNCIONAL**

**Fecha**: 2 de Marzo 2026  
**Suscripción**: Azure for Students (pablomega@unisabana.edu.co)  
**Cluster**: AKS East US (1 nodo Standard_B2s)

---

## 📊 Componentes Desplegados

| Componente | Status | Detalles |
|------------|--------|----------|
| **Microservicio .NET 10** | ✅ | ProductAPI - 6 endpoints CRUD + health |
| **Docker** | ✅ | Imagen multistage en ACR `productapiregistry163505.azurecr.io/productapi:latest` |
| **Kubernetes** | ✅ | AKS 1 nodo, 2 pods running, deployment ready |
| **HPA** | ✅ | Horizontal Pod Autoscaler (2-5 replicas, 80% CPU) |
| **NGINX Ingress** | ✅ | LoadBalancer IP: `20.84.230.209` |
| **Helm** | ✅ | Release "productapi" v3 con values-acr.yaml |
| **ArgoCD** | ✅ | Instalado, Application sincronizada, AutoSync activo |
| **Tests** | ✅ | 15 tests xUnit (100% passing) |
| **Swagger** | ✅ | OpenAPI documentación integrada |

---

## 🔗 ACCESO A SERVICIOS

### **API REST Microservicio**
```
Base URL: http://20.84.230.209
Endpoints:
  GET    http://20.84.230.209/api/products
  GET    http://20.84.230.209/api/products/{id}
  POST   http://20.84.230.209/api/products
  PUT    http://20.84.230.209/api/products/{id}
  DELETE http://20.84.230.209/api/products/{id}
  GET    http://20.84.230.209/api/products/health
```

### **Swagger UI**
```
URL: http://20.84.230.209/swagger
```

### **ArgoCD (si LoadBalancer IP disponible)**
```
URL: https://<ArgoCD-IP> (pendiente - cuota Azure agotada)
Usuario: admin
Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📋 VERIFICACIÓN DEL DEPLOYMENT

Ejecutar script de verificación:
```powershell
.\azure\verify-deploy.ps1
```

**Output esperado:**
```
✅ Namespace existe
✅ Deployment ready (2/2)
✅ Pods están Running (2)
✅ HPA configurado correctamente (2-5)
✅ Service configurado (ClusterIP)
✅ Ingress NGINX asignada (20.84.230.209)
✅ Application sincronizada (Synced)
✅ VERIFICACIÓN COMPLETADA
```

---

## 🛠️ COMANDOS ÚTILES

### **Ver estado general**
```bash
# Todos los recursos
kubectl get all -n productapi

# Solo pods
kubectl get pods -n productapi -o wide

# Deployment
kubectl get deployment -n productapi

# HPA
kubectl get hpa -n productapi

# Ingress
kubectl get ingress -n productapi

# Service
kubectl get svc -n productapi
```

### **Logs**
```bash
# Seguir logs en vivo
kubectl logs -n productapi -l app=productapi -f

# Últimas 100 líneas
kubectl logs -n productapi -l app=productapi --tail=100
```

### **Diagnostico**
```bash
# Ver eventos
kubectl get events -n productapi --sort-by='.lastTimestamp'

# Describe deployment
kubectl describe deployment productapi-productapi -n productapi

# Describe pod
kubectl describe pod <pod-name> -n productapi

# Port-forward para testing local
kubectl port-forward svc/productapi-productapi 8080:80 -n productapi
```

### **ArgoCD**
```bash
# Ver status de aplicación
kubectl get application -n argocd productapi -o yaml

# Trigger sync manual
kubectl patch application productapi -n argocd --type merge \
  --patch '{"status":{"sync":{"comparisonResult":{"status":""}}}}'

# Ver pods de ArgoCD
kubectl get pods -n argocd
```

---

## 📁 ESTRUCTURA DE DEPLOYMENT

```
Workspace/
├── src/ProductAPI/              # Microservicio .NET 10
│   ├── Models/Product.cs        # Domain model
│   ├── Controllers/             # REST API endpoints
│   ├── Repositories/            # In-memory data store
│   ├── Program.cs              # DI + Swagger configuration
│   └── ProductAPI.csproj
│
├── docker/
│   └── Dockerfile              # Multistage build (sdk → runtime)
│
├── helm/
│   ├── Chart.yaml              # Helm metadata
│   ├── values.yaml             # Default values
│   ├── values-acr.yaml         # ACR-specific values (versionado)
│   └── templates/
│       ├── deployment.yaml     # Kubernetes deployment
│       ├── service.yaml        # Service (ClusterIP)
│       ├── ingress.yaml        # NGINX Ingress
│       └── hpa.yaml            # HPA configuration
│
├── argocd/
│   ├── namespace.yaml
│   ├── application.yaml        # ArgoCD Application manifest
│   └── INSTALLATION.md
│
├── azure/
│   ├── create-aks-cluster.ps1        # Create AKS cluster
│   ├── setup-acr-and-deploy.ps1      # Build & deploy with Helm
│   ├── setup-argocd.ps1              # Install ArgoCD
│   ├── verify-deploy.ps1             # Verify deployment
│   └── delete-all-resources.ps1      # Cleanup
│
├── .github/workflows/
│   └── ci-cd.yml               # GitHub Actions pipeline
│
└── docs/
    ├── ARCHITECTURE.md
    ├── DEPLOYMENT_GUIDE.md
    ├── TESTING.md
    └── GETTING_STARTED.md
```

---

## 🔄 FLUJO DE DEPLOYMENT (GitOps con ArgoCD)

1. **Cambio en GitHub** → Merge a `main`
2. **CI/CD GitHub Actions** → Build image, push a ACR
3. **CI/CD actualiza** `helm/values-acr.yaml` con nueva imagen → Commit a `main`
4. **ArgoCD detecta** cambio en repo → Sincroniza automáticamente
5. **Helm aplica** deployment con nueva imagen
6. **Pods nuevos** reemplazan los antiguos (rolling update)

---

## 📊 ARQUITECTURA EN KUBERNETES

```
┌─────────────────────────────────────────────────────────────┐
│                    AZURE AKS CLUSTER                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─ Ingress Controller (NGINX) ◄─── LoadBalancer IP         │
│  │   20.84.230.209                                           │
│  │                                                            │
│  └─► Ingress (productapi-productapi)                        │
│       └─► Service ClusterIP (productapi-productapi:80)      │
│            └─► Deployment (productapi-productapi)           │
│                 ├─ Pod 1: productapi (CPU: 250m → 500m)     │
│                 └─ Pod 2: productapi (CPU: 250m → 500m)     │
│                                                               │
│  ┌─ HPA Monitor ◄─── Prometheus Metrics                     │
│  │  (2 min, 5 max replicas, 80% CPU threshold)             │
│  │                                                            │
│  └─► Scale Pods cuando CPU > 80%                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              ArgoCD (Namespace: argocd)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─ ArgoCD Server (LoadBalancer - PENDING IP)              │
│  ├─ ArgoCD Repo Server                                      │
│  ├─ ArgoCD Controller                                       │
│  └─ Application "productapi" (Synced ✅)                   │
│      └─ Watches: https://github.com/pmelo1981/...         │
│         Branch: main, Path: helm/                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 TESTING DEL API

### **Con PowerShell**
```powershell
# Test health endpoint
$response = Invoke-WebRequest -Uri "http://20.84.230.209/api/products/health" -UseBasicParsing
$response.StatusCode  # Expect: 200

# Get all products
$response = Invoke-WebRequest -Uri "http://20.84.230.209/api/products" -UseBasicParsing
$products = $response.Content | ConvertFrom-Json
$products  # Expect: array de productos
```

### **Con curl**
```bash
# Health check
curl -i http://20.84.230.209/api/products/health

# Get products
curl http://20.84.230.209/api/products | jq

# Create product
curl -X POST http://20.84.230.209/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99}'

# Get by ID
curl http://20.84.230.209/api/products/1

# Update
curl -X PUT http://20.84.230.209/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Gaming Laptop","price":1299.99}'

# Delete
curl -X DELETE http://20.84.230.209/api/products/1
```

---

## 🔧 CONFIGURACIÓN ACTUAL

### **AKS Cluster**
- **Nombre**: productapi-aks
- **Resource Group**: productapi-rg
- **Región**: East US
- **Nodos**: 1 x Standard_B2s
- **Kubernetes**: v1.33.6
- **Network Plugin**: kubenet

### **Azure Container Registry (ACR)**
- **Nombre**: productapiregistry163505
- **SKU**: Basic
- **Última imagen**: productapi:latest
- **URL**: productapiregistry163505.azurecr.io

### **Helm Release**
- **Nombre**: productapi
- **Namespace**: productapi
- **Chart**: Local (helm/)
- **Values**: values-acr.yaml
- **Revision**: 3

### **ArgoCD Application**
- **Nombre**: productapi
- **Repo**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3
- **Branch**: main
- **Path**: helm/
- **Auto Sync**: ✅ Enabled (prune + selfHeal)
- **Status**: Synced ✅

---

## ⚠️ LIMITACIONES ACTUALES (Azure for Students)

- **Límite de IPs Públicas**: 3 máximo por región
  - Usadas: NGINX LoadBalancer (1) + AKS API (1) = 2/3
  - Disponible: 1 (ArgoCD LoadBalancer está PENDING)
- **Solución**: Acceso a ArgoCD a través de port-forward local si es necesario

---

## 🐛 TROUBLESHOOTING

### **Pods no están running**
```bash
kubectl describe pod <pod-name> -n productapi
kubectl logs <pod-name> -n productapi
```

### **Ingress sin IP**
```bash
kubectl describe ingress productapi-productapi -n productapi
# Check NGINX controller status
kubectl get pods -n ingress-nginx
```

### **ArgoCD no sincroniza**
```bash
kubectl get application productapi -n argocd
kubectl describe application productapi -n argocd
# Check connectivity to repo
```

### **Imagen no pull (imagePullBackOff)**
```bash
# Verify ACR credentials
kubectl get secret -n productapi
# Recreate if needed
kubectl delete secret acr-auth -n productapi
kubectl create secret docker-registry acr-auth \
  --docker-server=productapiregistry163505.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password>
```

---

## 📝 PRÓXIMOS PASOS (Post-Deployment)

- [ ] Hacer Git push de cambios locales
- [ ] Configurar CI/CD para auto-deploy en cambios a `main`
- [ ] Asegurar ArgoCD IP disponible (esperar o limpieza de recursos)
- [ ] Implementar health checks más sofisticados
- [ ] Agregar resource quotas y pod disruption budgets
- [ ] Configurar logging centralizado (Azure Monitor/Loki)
- [ ] Implementar RBAC y Network Policies

---

## 📚 REFERENCIAS

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD GitOps](https://argoproj.github.io/argo-cd/)
- [Helm Package Manager](https://helm.sh/)
- [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

**Generado**: 2026-03-02  
**Verificación última**: ✅ PASSED (verify-deploy.ps1)  
**Maintainer**: Pablo Melogar (@pmelo1981)
