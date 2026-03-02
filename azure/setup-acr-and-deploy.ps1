# Script de despliegue en PowerShell
$ErrorActionPreference = "Stop"

Write-Host "Configurando Azure Container Registry y desplegando aplicacion..."

$RESOURCE_GROUP = "productapi-rg"
$CLUSTER_NAME = "productapi-aks"
$LOCATION = "centralus"
$REGISTRY_NAME = "productapiregistry$(Get-Date -Format 'HHmmss')"

$ACR_CREATED = $false
$HELM_DEPLOYED = $false

function Cleanup {
    Write-Host ""
    Write-Host "Error detectado. Limpiando recursos creados..."
    if ($HELM_DEPLOYED) {
        Write-Host "Eliminando despliegue de Helm..."
        try { helm uninstall productapi -n productapi 2>&1 | Out-Null } catch {}
        try { kubectl delete namespace productapi 2>&1 | Out-Null } catch {}
    }
    if ($ACR_CREATED) {
        Write-Host "Eliminando Azure Container Registry..."
        try { az acr delete --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP --yes 2>&1 | Out-Null } catch {}
    }
    Write-Host "Limpieza completada."
}

try {
    Write-Host ""
    Write-Host "Configuracion:"
    Write-Host "  Grupo de recursos: $RESOURCE_GROUP"
    Write-Host "  Cluster: $CLUSTER_NAME"
    Write-Host "  Registry: $REGISTRY_NAME"
    Write-Host "  Ubicacion: $LOCATION"
    Write-Host ""

    Write-Host "Verificando registro del proveedor Microsoft.ContainerRegistry..."
    az provider register --namespace Microsoft.ContainerRegistry --wait
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Creando Azure Container Registry..."
    az acr create --resource-group $RESOURCE_GROUP --name $REGISTRY_NAME --sku Basic --location $LOCATION --output none
    $ACR_CREATED = $true
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Obteniendo informacion del registry..."
    $ACR_LOGIN_SERVER = (az acr show --resource-group $RESOURCE_GROUP --name $REGISTRY_NAME --query loginServer -o tsv)
    # Limpiar caracteres de fin de linea Windows
    $ACR_LOGIN_SERVER = $ACR_LOGIN_SERVER -replace "`r|`n", ""
    $ACR_LOGIN_SERVER = $ACR_LOGIN_SERVER.Trim()
    Write-Host "URL del Registry: $ACR_LOGIN_SERVER"

    Write-Host ""
    Write-Host "Conectando ACR con el cluster AKS..."
    az aks update --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --attach-acr $REGISTRY_NAME --output none
    Write-Host "Completado."
    
    Write-Host ""
    Write-Host "Esperando propagacion de permisos ACR-AKS (60 segundos)..."
    Start-Sleep -Seconds 60
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Autenticando con ACR..."
    az acr login --name $REGISTRY_NAME --output none
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Construyendo imagen Docker para linux/amd64..."
    
    # Usar buildx con provenance y sbom deshabilitados para evitar manifests corruptos
    docker buildx build --platform linux/amd64 --provenance=false --sbom=false -f docker/Dockerfile -t "$ACR_LOGIN_SERVER/productapi:latest" --load .
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error construyendo la imagen Docker"
    }
    
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Subiendo imagen a ACR..."
    docker push "$ACR_LOGIN_SERVER/productapi:latest"
    Write-Host "Completado."
    
    Write-Host ""
    Write-Host "Verificando imagen en ACR..."
    $imageExists = az acr repository show --name $REGISTRY_NAME --repository productapi 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Imagen verificada en ACR."
    } else {
        Write-Host "ADVERTENCIA: No se pudo verificar la imagen en ACR."
    }

    Write-Host ""
    Write-Host "Creando archivo de valores para Helm..."
    @"
replicaCount: 2
image:
  repository: $ACR_LOGIN_SERVER/productapi
  tag: latest
  pullPolicy: Always
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
env:
  - name: ASPNETCORE_ENVIRONMENT
    value: Production
ingress:
  enabled: true
  host: ""
"@ | Out-File -FilePath "helm/values-acr.yaml" -Encoding UTF8 -NoNewline
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Desplegando aplicacion con Helm..."
    helm upgrade --install productapi helm/ --values helm/values-acr.yaml --create-namespace --namespace productapi
    $HELM_DEPLOYED = $true
    Write-Host "Completado."

    Write-Host ""
    Write-Host "Esperando que los pods esten listos (hasta 10 minutos)..."
    Write-Host "Puede tomar tiempo mientras descarga la imagen..."
    
    $waitSuccess = $false
    try {
        kubectl wait --for=condition=available --timeout=600s deployment/productapi-productapi -n productapi 2>&1 | Out-Null
        $waitSuccess = $true
        Write-Host "Pods listos."
    }
    catch {
        Write-Host "Timeout esperando pods. Verificando estado..."
        kubectl get pods -n productapi
        Write-Host ""
        Write-Host "Para ver logs detallados:"
        Write-Host "  kubectl describe pod -n productapi"
        Write-Host "  kubectl logs -n productapi -l app=productapi"
        Write-Host ""
        Write-Host "NOTA: El despliegue continua ejecutandose. Los recursos NO se eliminaron."
    }

    Write-Host ""
    Write-Host "Obteniendo IP del Ingress Controller..."
    $INGRESS_IP = ""
    for ($i = 1; $i -le 30; $i++) {
        $INGRESS_IP = (kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null)
        if ($INGRESS_IP) {
            break
        }
        Write-Host "Esperando asignacion de IP (intento $i/30)..."
        Start-Sleep -Seconds 10
    }

    Write-Host ""
    Write-Host "Estado del despliegue:"
    kubectl get all -n productapi
    Write-Host ""
    kubectl get ingress -n productapi

    Write-Host ""
    Write-Host "============================================"
    if ($waitSuccess) {
        Write-Host "Despliegue completado exitosamente"
    } else {
        Write-Host "Despliegue iniciado (verificar estado de pods)"
    }
    Write-Host "============================================"
    Write-Host ""
    Write-Host "Azure Container Registry:"
    Write-Host "  Registry: $ACR_LOGIN_SERVER"
    Write-Host "  Imagen: $ACR_LOGIN_SERVER/productapi:latest"
    Write-Host ""
    if ($INGRESS_IP) {
        Write-Host "Acceso a la aplicacion:"
        Write-Host "  IP:  http://$INGRESS_IP"
        Write-Host "  URL: http://productapi.centralus.cloudapp.azure.com"
        Write-Host ""
        Write-Host "Endpoints:"
        Write-Host "  http://productapi.centralus.cloudapp.azure.com/api/products/health"
        Write-Host "  http://productapi.centralus.cloudapp.azure.com/api/products"
    } else {
        Write-Host "IP del Ingress aun no asignada."
        Write-Host "Ejecutar: kubectl get svc ingress-nginx-controller -n ingress-nginx"
    }
    Write-Host ""
    Write-Host "Comandos utiles:"
    Write-Host "  kubectl get pods -n productapi"
    Write-Host "  kubectl logs -l app=productapi -n productapi -f"
    Write-Host "  kubectl get all -n productapi"
    Write-Host ""
}
catch {
    Cleanup
    throw
}
