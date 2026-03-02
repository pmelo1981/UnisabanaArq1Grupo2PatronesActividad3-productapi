# Script para eliminar TODOS los recursos del proyecto en Azure
$ErrorActionPreference = "Stop"

Write-Host "============================================"
Write-Host "ELIMINACION COMPLETA DE RECURSOS EN AZURE"
Write-Host "============================================"
Write-Host ""

$RESOURCE_GROUP = "productapi-rg"

Write-Host "ADVERTENCIA: Este script eliminara:"
Write-Host "  - Cluster AKS: productapi-aks"
Write-Host "  - Todos los Azure Container Registry del grupo"
Write-Host "  - Grupo de recursos completo: $RESOURCE_GROUP"
Write-Host "  - Todos los recursos asociados"
Write-Host ""
Write-Host "Esta accion NO SE PUEDE DESHACER."
Write-Host ""
$confirm = Read-Host "Escribir 'ELIMINAR' para confirmar (en mayusculas)"

if ($confirm -ne "ELIMINAR") {
    Write-Host "Operacion cancelada."
    exit 0
}

Write-Host ""
Write-Host "Iniciando eliminacion de recursos..."
Write-Host ""

try {
    # Verificar si el grupo de recursos existe
    $rgExists = az group exists --name $RESOURCE_GROUP
    
    if ($rgExists -eq "true") {
        Write-Host "Grupo de recursos encontrado. Listando recursos..."
        az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type}" -o table
        
        Write-Host ""
        Write-Host "Eliminando grupo de recursos (esto puede tomar varios minutos)..."
        az group delete --name $RESOURCE_GROUP --yes --no-wait
        
        Write-Host ""
        Write-Host "Eliminacion iniciada en segundo plano."
        Write-Host ""
        Write-Host "Para verificar el progreso:"
        Write-Host "  az group show --name $RESOURCE_GROUP"
        Write-Host ""
        Write-Host "El grupo desaparecera cuando la eliminacion este completa."
    } else {
        Write-Host "El grupo de recursos '$RESOURCE_GROUP' no existe."
        Write-Host "No hay nada que eliminar."
    }
}
catch {
    Write-Host "Error al eliminar recursos: $_"
    exit 1
}

Write-Host ""
Write-Host "============================================"
Write-Host "Proceso de eliminacion completado"
Write-Host "============================================"
