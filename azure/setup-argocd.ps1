#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Instala ArgoCD en AKS, aplica manifests desde el repo Infrastructure y obtiene credenciales.
.DESCRIPTION
  - Crea namespace argocd
  - Instala ArgoCD desde manifests oficiales
  - Espera a que argocd-server obtenga LoadBalancer IP
  - Clona repo Infrastructure y aplica Application manifests
  - Muestra comando para obtener admin password
.PARAMETER InfraRepo
  URL del repo de Infrastructure con los manifests de ArgoCD
.PARAMETER Timeout
  Timeout en segundos para esperar IP (default 600s = 10 min)
.PARAMETER Interval
  Intervalo entre polls en segundos (default 10s)
#>

param(
    [string]$InfraRepo = "https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-infrastructure.git",
    [int]$Timeout = 600,
    [int]$Interval = 10
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔄 INSTALAR ARGOCD Y APLICAR APPLICATION  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Cyan

try {
    # 1. Crear namespace argocd
    Write-Host "1️⃣  Creando namespace argocd..." -ForegroundColor Yellow
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ Namespace creado/verificado`n" -ForegroundColor Green

    # 2. Instalar ArgoCD desde manifests oficiales
    Write-Host "2️⃣  Instalando ArgoCD..." -ForegroundColor Yellow
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    Write-Host "✅ ArgoCD instalado`n" -ForegroundColor Green

    # 3. Esperar a que argocd-server esté disponible
    Write-Host "3️⃣  Esperando argocd-server (timeout: ${Timeout}s)..." -ForegroundColor Yellow
    $elapsed = 0
    while ($elapsed -lt $Timeout) {
        $deployment = kubectl get deployment -n argocd argocd-server -o jsonpath='{.status.readyReplicas}' 2>$null
        if ($deployment -eq "1") {
            Write-Host "✅ argocd-server disponible`n" -ForegroundColor Green
            break
        }
        Write-Host "⏳ Esperando... (${elapsed}s/${Timeout}s)" -ForegroundColor Gray
        Start-Sleep -Seconds $Interval
        $elapsed += $Interval
    }

    if ($elapsed -ge $Timeout) {
        throw "Timeout esperando argocd-server"
    }

    # 4. Exponer argocd-server como LoadBalancer y esperar IP
    Write-Host "4️⃣  Exponiendo argocd-server como LoadBalancer..." -ForegroundColor Yellow
    kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}' | Out-Null
    Write-Host "   Service patcheado a LoadBalancer`n" -ForegroundColor Green

    Write-Host "   Esperando IP de LoadBalancer (timeout: ${Timeout}s)..." -ForegroundColor Yellow
    $elapsed = 0
    $argocdIP = $null
    while ($elapsed -lt $Timeout) {
        $argocdIP = kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($argocdIP -and $argocdIP -ne "") {
            Write-Host "✅ LoadBalancer IP: $argocdIP`n" -ForegroundColor Green
            break
        }
        Write-Host "⏳ Esperando IP... (${elapsed}s/${Timeout}s)" -ForegroundColor Gray
        Start-Sleep -Seconds $Interval
        $elapsed += $Interval
    }

    if (-not $argocdIP -or $argocdIP -eq "") {
        Write-Host "⚠️  LoadBalancer IP no disponible (puede estar pendiente)" -ForegroundColor Yellow
        $argocdIP = "<PENDING>"
    }

    # 5. Clonar repo Infrastructure y aplicar manifests de ArgoCD
    Write-Host "5️⃣  Clonando repo Infrastructure para obtener manifests..." -ForegroundColor Yellow
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "argocd-infra-$(Get-Random)"
    git clone --depth 1 $InfraRepo $tempDir 2>&1 | Out-Null

    if (-not (Test-Path "$tempDir/argocd/applications/productapi.yaml")) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        throw "productapi.yaml no encontrado en repo Infrastructure"
    }

    kubectl apply -f "$tempDir/argocd/applications/productapi.yaml"
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    Write-Host "✅ Application aplicada desde repo Infrastructure`n" -ForegroundColor Green

    # 6. Crear namespace productapi si no existe
    Write-Host "6️⃣  Asegurando namespace productapi..." -ForegroundColor Yellow
    kubectl create namespace productapi --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ Namespace productapi listo`n" -ForegroundColor Green

    # 7. Mostrar información de acceso
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ ARGOCD INSTALADO EXITOSAMENTE           ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Green

    Write-Host "📍 ACCESO ARGOCD:" -ForegroundColor Cyan
    Write-Host "   URL: https://$argocdIP" -ForegroundColor White
    Write-Host "   Usuario: admin`n" -ForegroundColor White

    Write-Host "🔐 OBTENER PASSWORD:" -ForegroundColor Cyan
    Write-Host "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d`n`n" -ForegroundColor White

    Write-Host "📊 VERIFICAR ESTADO:" -ForegroundColor Cyan
    Write-Host "   kubectl get application -n argocd" -ForegroundColor White
    Write-Host "   kubectl get pods -n productapi" -ForegroundColor White
    Write-Host "   kubectl get svc -n productapi`n`n" -ForegroundColor White

    Write-Host "⏭️  PRÓXIMO PASO: Ejecutar verify-deploy.ps1" -ForegroundColor Yellow

} catch {
    Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    exit 1
}
