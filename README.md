# 🚀 Master WordPress Infrastructure

A complete, enterprise-grade WordPress infrastructure deployment using AWS CloudFormation with High Availability, Security, and Global CDN.

## 🏗️ Architecture Overview

This infrastructure provides a production-ready WordPress hosting solution with:

- **High Availability**: Multi-AZ deployment across 2 Availability Zones
- **Auto Scaling**: 2-4 EC2 instances with Application Load Balancer
- **Database**: RDS MySQL Multi-AZ with automatic failover
- **Shared Storage**: EFS file system for wp-content/uploads
- **Global CDN**: CloudFront distribution with custom security headers
- **Security**: Private subnets, NAT Gateways, security groups
- **SSL/TLS**: Automatic HTTPS redirection via CloudFront

## 💰 Cost Estimate

**Monthly Cost**: ~$152.75
- 2x t3.micro EC2 instances: $16.06
- 2x NAT Gateways: $90.00
- Application Load Balancer: $16.20
- RDS t3.micro Multi-AZ: $24.48
- EFS: $0.01
- CloudFront: $1.00
- Other services: $5.00

## 🚀 Quick Deployment

### Option 1: One-Click Deployment (Recommended)
```bash
# Double-click to deploy with default settings
deploy.bat
```

### Option 2: PowerShell with Custom Parameters
```powershell
# Deploy with custom settings
.\deploy-master-infrastructure.ps1 -ProjectName "my-wordpress" -DBPassword "MySecurePassword123!"
```

### Option 3: AWS CLI Direct
```bash
aws cloudformation create-stack \
  --stack-name wordpress-ha-infrastructure \
  --template-body file://Master-WordPress-Infrastructure.yaml \
  --parameters ParameterKey=ProjectName,ParameterValue=wordpress-ha \
               ParameterKey=DBPassword,ParameterValue=YourSecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

## 📋 Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   ```

2. **PowerShell (for Windows deployment scripts)**

3. **AWS Account with appropriate permissions**
   - EC2, VPC, RDS, EFS, CloudFront, IAM, CloudFormation

## ⚙️ Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ProjectName` | `wordpress-ha` | Project name for resource naming |
| `KeyPairName` | `wp-master-key` | EC2 Key Pair (created automatically) |
| `DomainName` | `""` | Custom domain (optional, uses CloudFront domain if empty) |
| `DBUsername` | `wpuser` | Database username |
| `DBPassword` | `WPPassword123!` | Database password (min 8 chars) |

## 🏗️ Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/16 with DNS support
- **Public Subnets**: 10.0.1.0/24 (us-east-1a), 10.0.4.0/24 (us-east-1c)
- **Private Subnets**: 10.0.5.0/24 (us-east-1a), 10.0.3.0/24 (us-east-1c)
- **NAT Gateways**: One per AZ for true redundancy
- **Internet Gateway**: For public internet access

### Compute
- **Auto Scaling Group**: 2-4 t3.micro instances
- **Launch Template**: Amazon Linux 2023 with WordPress
- **Application Load Balancer**: HTTP/HTTPS with health checks
- **Security Groups**: Layered security model

### Database & Storage
- **RDS MySQL**: t3.micro Multi-AZ with 7-day backups
- **EFS**: Shared file system for WordPress uploads
- **Encryption**: EFS encrypted at rest

### CDN & Security
- **CloudFront**: Global CDN with custom security headers
- **Custom Header Security**: Blocks direct ALB access
- **SSL/TLS**: Automatic HTTPS redirection
- **WAF Ready**: CloudFront distribution ready for WAF integration

## 🔧 Post-Deployment Steps

1. **Wait 5-10 minutes** for complete initialization
2. **Access your site**: Use the CloudFront URL from deployment output
3. **Complete WordPress setup**: Visit `/wp-admin/install.php`
4. **Configure WordPress**: Set up admin user, site title, etc.

## 📊 Monitoring & Management

### CloudFormation Stack
```bash
# View stack status
aws cloudformation describe-stacks --stack-name wordpress-ha-infrastructure

# View stack events
aws cloudformation describe-stack-events --stack-name wordpress-ha-infrastructure

# Delete entire infrastructure
aws cloudformation delete-stack --stack-name wordpress-ha-infrastructure
```

### Key Resources
- **CloudFront Distribution**: Global CDN endpoint
- **Application Load Balancer**: Traffic distribution
- **Auto Scaling Group**: Instance management
- **RDS Database**: WordPress data storage
- **EFS File System**: Shared WordPress uploads

## 🛡️ Security Features

### Network Security
- **Private Subnets**: WordPress instances not directly accessible
- **Security Groups**: Least-privilege access rules
- **NAT Gateways**: Secure outbound internet access

### Application Security
- **Custom Headers**: CloudFront-to-ALB authentication
- **HTTPS Enforcement**: Automatic SSL/TLS redirection
- **Database Security**: RDS in private subnets only

### Access Control
- **IAM Roles**: EC2 instances with minimal required permissions
- **Key Pairs**: SSH access via AWS-managed key pairs
- **Systems Manager**: Secure instance management without SSH

## 🔄 High Availability Features

### Multi-AZ Deployment
- **EC2 Instances**: Distributed across 2 AZs
- **RDS Database**: Multi-AZ with automatic failover
- **NAT Gateways**: One per AZ for redundancy
- **EFS Mount Targets**: Available in both AZs

### Auto Scaling
- **Health Checks**: ELB health checks with auto-replacement
- **Scaling Policies**: Ready for CloudWatch-based scaling
- **Load Balancing**: Even traffic distribution

### Disaster Recovery
- **RDS Backups**: 7-day automated backups
- **Multi-AZ RDS**: Synchronous replication
- **EFS Durability**: 99.999999999% (11 9's) durability

## 📈 Scaling & Optimization

### Horizontal Scaling
```bash
# Increase desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name wordpress-ha-asg \
  --desired-capacity 4
```

### Performance Optimization
- **CloudFront Caching**: Global edge locations
- **EFS Performance**: Burst throughput mode
- **RDS Optimization**: Multi-AZ for read performance

### Cost Optimization
- **Right-sizing**: t3.micro instances for development
- **Reserved Instances**: Consider for production workloads
- **Spot Instances**: Possible for non-critical environments

## 🚨 Troubleshooting

### Common Issues

**Deployment Fails**
```bash
# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name wordpress-ha-infrastructure
```

**Website Not Accessible**
1. Check CloudFront distribution status
2. Verify ALB target health
3. Ensure security groups allow traffic

**Database Connection Issues**
1. Verify RDS instance status
2. Check security group rules
3. Validate database credentials

### Health Checks
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names wordpress-ha-asg

# Check RDS status
aws rds describe-db-instances --db-instance-identifier wordpress-ha-db
```

## 📚 Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [WordPress on AWS Best Practices](https://aws.amazon.com/getting-started/hands-on/deploy-wordpress-with-amazon-rds/)
- [CloudFront Security Headers](https://docs.aws.amazon.com/cloudfront/latest/developerguide/adding-response-headers.html)

## 🤝 Support

This infrastructure template provides enterprise-grade WordPress hosting with:
- **99.99% Uptime** capability
- **Global Performance** via CloudFront CDN
- **Automatic Scaling** based on demand
- **Security Best Practices** implementation
- **Cost-Optimized** resource allocation

For issues or enhancements, review the CloudFormation template and deployment scripts in this repository.

---

**🎯 Result**: Production-ready WordPress infrastructure that can handle significant traffic, survive AZ failures, and provide global performance at an optimized cost of ~$152.75/month.