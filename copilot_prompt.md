# 🤖 Copilot Prompt - ProductAPI Repository

## Contexto del Proyecto

Este repositorio contiene el **código fuente de la aplicación** ProductAPI.

- **Tecnología**: .NET 10 ASP.NET Core
- **Patrón**: 3 capas (Models → Controllers → Repositories)
- **Tests**: 15 xUnit (100% passing)
- **Deployment**: Kubernetes + Helm + ArgoCD
- **CI/CD**: GitHub Actions (auto-build & deploy)

---

## Estructura del Proyecto

```
src/
├── ProductAPI/
│   ├── Program.cs           # DI, Swagger, Health endpoint
│   ├── Controllers/ProductsController.cs
│   ├── Models/Product.cs
│   └── Repositories/ProductRepository.cs
└── ProductAPI.Tests/

docker/
└── Dockerfile              # Multistage: SDK → ASPNet runtime

helm/
├── Chart.yaml
├── values.yaml
├── values-acr.yaml         # VERSIONADO - Updated by CI/CD
└── templates/

.github/workflows/
└── ci-cd.yml               # Triggers on push to main

azure/
└── *.ps1                    # Deployment scripts
```

---

## Tareas Comunes con Copilot

### "Necesito añadir un nuevo endpoint"

```csharp
// En: src/ProductAPI/Controllers/ProductsController.cs

[HttpGet("new-action")]
public ActionResult<IEnumerable<Product>> NewAction()
{
    // tu lógica
    return Ok(_repository.GetAll());
}
```

Luego:
```bash
dotnet test        # Verifica que compila
git add .
git commit -m "feat: add new endpoint"
git push           # Triggerea CI/CD automáticamente
```

### "Quiero actualizar la imagen en production"

**NO hagas esto:**
```bash
# ❌ NO edites values-acr.yaml manually
```

**Haz esto:**
```bash
# ✅ Actualiza código → push → GitHub Actions hace todo
git add .
git commit -m "fix: something"
git push origin main
# GitHub Actions: build → test → docker push → update values-acr.yaml → auto-deploy
```

### "Necesito cambiar réplicas/recursos"

```bash
# Edita: helm/values.yaml
replicaCount: 5          # Cambiar réplicas
resources.cpu: 500m      # Cambiar CPU

git add helm/values.yaml
git commit -m "config: increase replicas to 5"
git push
# ArgoCD detecta → auto-sincroniza
```

### "Quiero ejecutar los tests"

```bash
# Todos
dotnet test

# Específico
dotnet test --filter "ProductRepository"

# Con coverage
dotnet test /p:CollectCoverage=true
```

### "Necesito debuggear un endpoint"

```bash
# Terminal 1: ejecutar app
dotnet run --project src/ProductAPI/ProductAPI.csproj

# Terminal 2: test
curl http://localhost:5000/api/products

# O usar Swagger: http://localhost:5000/swagger
```

### "La build falló, ¿qué hago?"

```bash
# Ver logs de GitHub Actions
# 1. Ir a: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-productapi/actions
# 2. Click en el workflow fallido
# 3. Ver detalles del error

# Troubleshooting comun:
dotnet clean
dotnet restore
dotnet build -c Release
dotnet test

# Si es problema de Docker:
docker build -f docker/Dockerfile -t productapi:test .
```

### "¿Cómo está el deployment en el cluster?"

```bash
# Ver pods
kubectl get pods -n productapi

# Ver logs
kubectl logs -n productapi -l app=productapi -f

# Ver status de ArgoCD
kubectl get application -n argocd

# Verificar sincronización
argocd app get productapi

# Health check
curl http://INGRESS_IP/api/products/health
```

---

## Flujo de Desarrollo Típico

1. **Hacer cambios en código**
   ```bash
   # Edita src/ProductAPI/Controllers/ProductsController.cs
   # O src/ProductAPI/Repositories/ProductRepository.cs
   ```

2. **Ejecutar tests localmente**
   ```bash
   dotnet test
   # Debe pasar todos 15 tests
   ```

3. **Commit y push**
   ```bash
   git add .
   git commit -m "feat: new feature description"
   git push origin main
   ```

4. **GitHub Actions se triggerea automáticamente**
   - Build
   - Test
   - Docker build & push a ACR
   - Update values-acr.yaml
   - Commit + push

5. **ArgoCD detecta cambio y despliega**
   - Sincroniza helm/ con new image
   - Kubernetes crea new pods
   - Deployment completo ✅

---

## Mejores Prácticas

| Aspecto | ✅ Haz | ❌ NO hagas |
|--------|------|-----------|
| **Tests** | `dotnet test` antes de push | Pushear sin testing |
| **Commits** | Mensajes descriptivos | "Fix" o "Update" sin detalles |
| **Values** | Edita values.yaml en repo | Modifies pods manualmente |
| **Images** | CI/CD automático (push code) | Push image manualmente |
| **Version** | Semantic versioning (v1.0.0) | Sin versionado claro |

---

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| Tests fallan | Código incorrecto | `dotnet test` local primero |
| Docker build falla | SDK version mismatch | Usa .NET 10 |
| Pod CrashLoopBackOff | Image corrupt o config error | `kubectl logs` + check values.yaml |
| ArgoCD no sincroniza | Git credentials error | Ver copilot_prompt.md en Infrastructure repo |

---

## Enlaces Rápidos

- **GitHub Repo**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-productapi
- **Infrastructure Repo**: https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure
- **.NET 10 Docs**: https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10
- **xUnit Testing**: https://xunit.net/
- **Kubernetes**: https://kubernetes.io/docs/
- **ArgoCD**: https://argo-cd.readthedocs.io/

---

**Última actualización:** 2024
