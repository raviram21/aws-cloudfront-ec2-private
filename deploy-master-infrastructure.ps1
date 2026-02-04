# ===================================================================
# Master WordPress Infrastructure Deployment Script
# ===================================================================
# This script deploys a complete enterprise-grade WordPress infrastructure
# with High Availability, Security, and CloudFront CDN using CloudFormation
# ===================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "wordpress-ha",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyPairName = "wp-master-key",
    
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DBUsername = "wpuser",
    
    [Parameter(Mandatory=$false)]
    [string]$DBPassword = "WPPassword123!",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"
$White = "White"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-AWSCLIInstalled {
    try {
        $null = aws --version
        return $true
    }
    catch {
        return $false
    }
}

function Test-AWSCredentials {
    try {
        $null = aws sts get-caller-identity --region $Region
        return $true
    }
    catch {
        return $false
    }
}

# ===================================================================
# MAIN DEPLOYMENT SCRIPT
# ===================================================================

Write-Status "=================================================================" $Cyan
Write-Status "  🚀 MASTER WORDPRESS INFRASTRUCTURE DEPLOYMENT" $Cyan
Write-Status "=================================================================" $Cyan
Write-Status ""

# Validate prerequisites
Write-Status "📋 Checking Prerequisites..." $Yellow
Write-Status ""

if (-not (Test-AWSCLIInstalled)) {
    Write-Status "❌ AWS CLI is not installed or not in PATH" $Red
    Write-Status "Please install AWS CLI: https://aws.amazon.com/cli/" $Red
    exit 1
}
Write-Status "✅ AWS CLI is installed" $Green

if (-not (Test-AWSCredentials)) {
    Write-Status "❌ AWS credentials not configured or invalid" $Red
    Write-Status "Please run: aws configure" $Red
    exit 1
}
Write-Status "✅ AWS credentials are valid" $Green

# Check if template exists
$templatePath = "Master-WordPress-Infrastructure.yaml"
if (-not (Test-Path $templatePath)) {
    Write-Status "❌ CloudFormation template not found: $templatePath" $Red
    exit 1
}
Write-Status "✅ CloudFormation template found" $Green

Write-Status ""
Write-Status "📊 Deployment Configuration:" $Cyan
Write-Status "• Project Name: $ProjectName" $White
Write-Status "• AWS Region: $Region" $White
Write-Status "• Key Pair Name: $KeyPairName" $White
Write-Status "• Database Username: $DBUsername" $White
Write-Status "• Custom Domain: $(if ($DomainName) { $DomainName } else { 'None (will use CloudFront domain)' })" $White
Write-Status ""

# Confirm deployment
$confirm = Read-Host "Do you want to proceed with deployment? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Status "Deployment cancelled by user." $Yellow
    exit 0
}

Write-Status ""
Write-Status "🚀 Starting CloudFormation deployment..." $Yellow
Write-Status ""

# Prepare parameters
$parameters = @(
    "ParameterKey=ProjectName,ParameterValue=$ProjectName",
    "ParameterKey=KeyPairName,ParameterValue=$KeyPairName",
    "ParameterKey=DBUsername,ParameterValue=$DBUsername",
    "ParameterKey=DBPassword,ParameterValue=$DBPassword"
)

if ($DomainName) {
    $parameters += "ParameterKey=DomainName,ParameterValue=$DomainName"
}

$stackName = "$ProjectName-infrastructure"

# Deploy CloudFormation stack
try {
    Write-Status "Creating CloudFormation stack: $stackName" $Yellow
    
    $deployCommand = "aws cloudformation create-stack --stack-name `"$stackName`" --template-body file://$templatePath --parameters $($parameters -join ' ') --capabilities CAPABILITY_NAMED_IAM --region $Region"
    
    $result = Invoke-Expression $deployCommand | ConvertFrom-Json
    $stackId = $result.StackId
    
    Write-Status "✅ Stack creation initiated: $stackId" $Green
    Write-Status ""
    
    Write-Status "⏳ Waiting for stack creation to complete..." $Yellow
    Write-Status "This typically takes 10-15 minutes for the complete infrastructure..." $Yellow
    Write-Status ""
    
    # Monitor stack creation
    $maxWaitTime = 1800  # 30 minutes
    $waitTime = 0
    $checkInterval = 30
    
    do {
        Start-Sleep -Seconds $checkInterval
        $waitTime += $checkInterval
        
        $stackStatus = aws cloudformation describe-stacks --stack-name $stackName --region $Region --query "Stacks[0].StackStatus" --output text
        
        $elapsedMinutes = [math]::Floor($waitTime / 60)
        $elapsedSeconds = $waitTime % 60
        
        switch ($stackStatus) {
            "CREATE_IN_PROGRESS" {
                Write-Status "⏳ Stack creation in progress... (${elapsedMinutes}m ${elapsedSeconds}s elapsed)" $Yellow
            }
            "CREATE_COMPLETE" {
                Write-Status "✅ Stack creation completed successfully!" $Green
                break
            }
            "CREATE_FAILED" {
                Write-Status "❌ Stack creation failed!" $Red
                $events = aws cloudformation describe-stack-events --stack-name $stackName --region $Region --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].{Resource:LogicalResourceId,Reason:ResourceStatusReason}" --output table
                Write-Status "Failed resources:" $Red
                Write-Status $events $Red
                exit 1
            }
            "ROLLBACK_IN_PROGRESS" {
                Write-Status "⚠️ Stack creation failed, rollback in progress..." $Yellow
            }
            "ROLLBACK_COMPLETE" {
                Write-Status "❌ Stack creation failed and rolled back!" $Red
                exit 1
            }
            default {
                Write-Status "⚠️ Unexpected stack status: $stackStatus" $Yellow
            }
        }
        
        if ($waitTime -ge $maxWaitTime) {
            Write-Status "❌ Deployment timed out after 30 minutes" $Red
            exit 1
        }
        
    } while ($stackStatus -ne "CREATE_COMPLETE")
    
    Write-Status ""
    Write-Status "🎉 DEPLOYMENT SUCCESSFUL!" $Green
    Write-Status ""
    
    # Get stack outputs
    Write-Status "📊 Infrastructure Details:" $Cyan
    Write-Status ""
    
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --region $Region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    
    foreach ($output in $outputs) {
        $key = $output.OutputKey
        $value = $output.OutputValue
        $description = $output.Description
        
        Write-Status "• $description" $White
        Write-Status "  $key: $value" $Green
        Write-Status ""
    }
    
    # Get CloudFront URL for easy access
    $cloudfrontUrl = ($outputs | Where-Object { $_.OutputKey -eq "CloudFrontURL" }).OutputValue
    
    Write-Status "=================================================================" $Cyan
    Write-Status "  🌟 DEPLOYMENT COMPLETE - INFRASTRUCTURE READY!" $Cyan
    Write-Status "=================================================================" $Cyan
    Write-Status ""
    Write-Status "🔗 Your WordPress site is available at:" $Green
    Write-Status "   $cloudfrontUrl" $Green
    Write-Status ""
    Write-Status "⏰ Please wait 5-10 minutes for:" $Yellow
    Write-Status "   • EC2 instances to fully initialize" $Yellow
    Write-Status "   • WordPress installation to complete" $Yellow
    Write-Status "   • CloudFront distribution to propagate globally" $Yellow
    Write-Status ""
    Write-Status "🏗️ Infrastructure Features:" $Cyan
    Write-Status "   ✅ High Availability across 2 Availability Zones" $Green
    Write-Status "   ✅ Auto Scaling Group with 2-4 instances" $Green
    Write-Status "   ✅ Application Load Balancer with health checks" $Green
    Write-Status "   ✅ RDS MySQL Multi-AZ database" $Green
    Write-Status "   ✅ EFS shared file system" $Green
    Write-Status "   ✅ CloudFront CDN with custom security headers" $Green
    Write-Status "   ✅ Private subnets with NAT Gateways" $Green
    Write-Status "   ✅ SSL/TLS encryption" $Green
    Write-Status ""
    Write-Status "💰 Estimated Monthly Cost: `$152.75" $Green
    Write-Status ""
    Write-Status "🔧 Next Steps:" $Yellow
    Write-Status "   1. Visit $cloudfrontUrl" $White
    Write-Status "   2. Complete WordPress setup at $cloudfrontUrl/wp-admin/install.php" $White
    Write-Status "   3. Configure your WordPress site" $White
    Write-Status ""
    Write-Status "📚 Management:" $Yellow
    Write-Status "   • View resources: AWS Console > CloudFormation > $stackName" $White
    Write-Status "   • Delete infrastructure: aws cloudformation delete-stack --stack-name $stackName --region $Region" $White
    Write-Status ""
    
}
catch {
    Write-Status "❌ Deployment failed: $($_.Exception.Message)" $Red
    exit 1
}

Write-Status "Deployment script completed successfully! 🎉" $Green