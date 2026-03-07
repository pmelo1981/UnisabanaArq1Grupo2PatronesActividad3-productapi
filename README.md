# Product API - Microservicio REST

API REST para gestión de productos con despliegue en Kubernetes/AKS, Helm, ArgoCD y CI/CD.

**Acceso en vivo (Ingress IP):** http://172.168.96.52/api/products

---

## Tecnologías

- .NET 10
- Docker
- Kubernetes/AKS
- Helm
- NGINX Ingress Controller
- ArgoCD
- GitHub Actions
- Azure Container Registry

---

## Endpoints principales

GET    /api/products
GET    /api/products/{id}
GET    /api/products/stats
POST   /api/products
PUT    /api/products/{id}
DELETE /api/products/{id}
GET    /api/products/health

---

## Acceso en vivo (detalles)

Base URL (IP Ingress):
```
http://172.168.96.52
```

Health:
```
curl http://172.168.96.52/api/products/health
```

Swagger:
```
http://172.168.96.52/swagger
```

Crear producto (ejemplo):
```
curl -X POST http://172.168.96.52/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"Gaming laptop","price":1299.99}'
```

---

## Despliegue / CI

Las imágenes se publican en ACR y el despliegue se realiza vía ArgoCD/Helm. Valores actuales en helm/values-acr.yaml:
```
repository: productapiacrmpn.azurecr.io/productapi
tag: 8e69a02dc456a0b837aa6e7ba33330babe1f5c21
```

---

## Infra / ArgoCD

ArgoCD UI:
```
http://172.169.162.125
```

---

**Última actualización:** 07/03/2026
