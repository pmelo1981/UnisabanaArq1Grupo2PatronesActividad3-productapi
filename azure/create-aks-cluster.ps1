# Script para crear cluster AKS en Azure
$ErrorActionPreference = "Stop"

$RESOURCE_GROUP = "productapi-rg"
$AKS_CLUSTER = "productapi-aks"
$LOCATION = "centralus"
$NODE_COUNT = 1
$VM_SIZE = "Standard_D2s_v3"
$DNS_LABEL = "productapi"

function Cleanup {
    Write-Host "Error detectado. Limpiando recursos..."
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    Write-Host "Eliminacion de grupo de recursos iniciada."
}

try {
    Write-Host "Creando grupo de recursos..."
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none

    Write-Host "Iniciando creacion del cluster AKS..."
    az aks create `
        --resource-group $RESOURCE_GROUP `
        --name $AKS_CLUSTER `
        --node-count $NODE_COUNT `
        --node-vm-size $VM_SIZE `
        --load-balancer-sku standard `
        --enable-managed-identity `
        --network-plugin azure `
        --network-policy azure `
        --no-wait `
        --output none

    Write-Host "Esperando provision del cluster..."
    az aks wait --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --created

    Write-Host "Obteniendo credenciales de AKS..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing --output none

    Write-Host "Instalando NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

    Write-Host "Esperando que el Ingress Controller este listo..."
    kubectl wait --namespace ingress-nginx --for=condition=available --timeout=300s deployment/ingress-nginx-controller 2>$null
    if ($LASTEXITCODE -ne 0) {
        Start-Sleep -Seconds 15
        kubectl wait --namespace ingress-nginx --for=condition=available --timeout=300s deployment/ingress-nginx-controller
    }

    Write-Host "Asignando DNS de Azure al Ingress Controller..."
    kubectl annotate svc ingress-nginx-controller -n ingress-nginx service.beta.kubernetes.io/azure-dns-label-name=$DNS_LABEL

    Write-Host "Esperando asignacion de IP..."
    $INGRESS_IP = ""
    for ($i = 1; $i -le 30; $i++) {
        $INGRESS_IP = (kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null)
        if ($INGRESS_IP) { break }
        Write-Host "  Esperando IP (intento $i/30)..."
        Start-Sleep -Seconds 10
    }

    Write-Host ""
    Write-Host "============================================"
    Write-Host "Cluster AKS creado exitosamente"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "IP del Ingress: $INGRESS_IP"
    Write-Host "URL fija:       http://$DNS_LABEL.$LOCATION.cloudapp.azure.com"
    Write-Host ""
}
catch {
    Cleanup
    throw
}
