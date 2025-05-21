#!/bin/bash
set -e

echo "Desplegando Ponchoneta Fútbol en AWS..."

echo "Paso 1: Crear VPC y subredes públicas"
aws cloudformation deploy \
  --template-file cloudformation/vpc.yaml \
  --stack-name ponchoneta-vpc \
  --capabilities CAPABILITY_NAMED_IAM

VPC_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaVPC'].OutputValue" --output text)
SUBNET1=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet1'].OutputValue" --output text)
SUBNET2=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet2'].OutputValue" --output text)

echo "Paso 2: Crear grupos de seguridad"
aws cloudformation deploy \
  --template-file cloudformation/security-groups.yaml \
  --stack-name ponchoneta-sg \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID

APP_SG=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaAppSecurityGroup'].OutputValue" --output text)
ALB_SG=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaALBSecurityGroup'].OutputValue" --output text)

echo "Paso 3: Crear base de datos RDS MySQL"
read -sp "Ingresa la contraseña para la base de datos RDS: " DB_PASSWORD
echo

aws cloudformation deploy \
  --template-file cloudformation/rds.yaml \
  --stack-name ponchoneta-db \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID Subnet1=$SUBNET1 Subnet2=$SUBNET2 DBPassword=$DB_PASSWORD

DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ponchoneta-db --query "Stacks[0].Outputs[?OutputKey=='PonchonetaDBEndpoint'].OutputValue" --output text)

echo "Paso 4: Crear Load Balancer (ALB)"
aws cloudformation deploy \
  --template-file cloudformation/alb.yaml \
  --stack-name ponchoneta-alb \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Subnet1=$SUBNET1 Subnet2=$SUBNET2 ALBSecurityGroup=$ALB_SG

TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name ponchoneta-alb --query "Stacks[0].Outputs[?OutputKey=='PonchonetaTargetGroup'].OutputValue" --output text)

echo "Paso 5: Crear Auto Scaling Group con EC2"
aws cloudformation deploy \
  --template-file cloudformation/ec2-autoscaling.yaml \
  --stack-name ponchoneta-app \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    VPC=$VPC_ID \
    Subnet1=$SUBNET1 \
    Subnet2=$SUBNET2 \
    AppSecurityGroup=$APP_SG \
    TargetGroup=$TARGET_GROUP_ARN \
    DBEndpoint=$DB_ENDPOINT

ALB_DNS=$(aws cloudformation describe-stacks --stack-name ponchoneta-alb --query "Stacks[0].Outputs[?OutputKey=='PonchonetaALBDNS'].OutputValue" --output text)

echo "Despliegue completado con éxito."
echo "Accede a la app en: http://$ALB_DNS"
