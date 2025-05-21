#!/bin/bash

set -e

echo "1. Creando stack VPC..."
aws cloudformation deploy \
  --template-file cloudformation/vpc.yaml \
  --stack-name ponchoneta-vpc \
  --capabilities CAPABILITY_NAMED_IAM

echo "2. Extrayendo IDs VPC y Subnets..."
VPC_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc \
  --query "Stacks[0].Outputs[?OutputKey=='PonchonetaVPC'].OutputValue" --output text)

SUBNET1=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc \
  --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet1'].OutputValue" --output text)

SUBNET2=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc \
  --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet2'].OutputValue" --output text)

echo "VPC_ID: $VPC_ID"
echo "SUBNET1: $SUBNET1"
echo "SUBNET2: $SUBNET2"

if [[ -z "$SUBNET1" || -z "$SUBNET2" || -z "$VPC_ID" ]]; then
  echo "Error: No se pudieron obtener VPC o Subnets. Abortando."
  exit 1
fi

echo "3. Creando Security Group para ALB..."

# Crear Security Group con nombre PonchonetaALBSG, si no existe
SG_NAME="PonchonetaALBSG"

# Verificar si existe el SG
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text)

if [[ "$SG_ID" == "None" ]]; then
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SG_NAME \
    --description "Security Group para Application Load Balancer Ponchoneta" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)
  echo "Security Group creado: $SG_ID"

  echo "Agregando regla de ingreso HTTP (puerto 80) para todo el mundo..."
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
else
  echo "Security Group ya existe: $SG_ID"
fi

echo "4. Desplegando stack ALB..."

aws cloudformation deploy \
  --template-file cloudformation/alb.yaml \
  --stack-name ponchoneta-alb \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Subnet1=$SUBNET1 Subnet2=$SUBNET2 ALBSecurityGroup=$SG_ID

echo "Despliegue completado con éxito."
