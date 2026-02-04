@echo off
REM ===================================================================
REM Quick Deploy Script for Master WordPress Infrastructure
REM ===================================================================
REM This batch file provides a simple way to deploy the complete
REM WordPress infrastructure with default settings
REM ===================================================================

echo.
echo ================================================================
echo   🚀 QUICK DEPLOY - WORDPRESS HA INFRASTRUCTURE
echo ================================================================
echo.
echo This will deploy a complete enterprise-grade WordPress infrastructure:
echo   • High Availability across 2 Availability Zones
echo   • Auto Scaling with Application Load Balancer  
echo   • RDS MySQL Multi-AZ Database
echo   • EFS Shared File System
echo   • CloudFront CDN with Security Headers
echo   • Private Subnets with NAT Gateways
echo.
echo Estimated Monthly Cost: $152.75
echo Deployment Time: 10-15 minutes
echo.

set /p confirm="Do you want to proceed with default settings? (y/N): "
if /i not "%confirm%"=="y" (
    echo Deployment cancelled.
    pause
    exit /b 0
)

echo.
echo Starting deployment with PowerShell...
echo.

powershell.exe -ExecutionPolicy Bypass -File "deploy-master-infrastructure.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================================================
    echo   ✅ DEPLOYMENT COMPLETED SUCCESSFULLY!
    echo ================================================================
    echo.
) else (
    echo.
    echo ================================================================
    echo   ❌ DEPLOYMENT FAILED!
    echo ================================================================
    echo.
)

pause