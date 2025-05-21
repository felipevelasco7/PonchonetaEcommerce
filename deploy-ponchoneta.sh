#!/bin/bash

# deploy-ponchoneta.sh
# Script para desplegar la infraestructura completa de Ponchoneta Fútbol en AWS.

# Configuración
# AWS_REGION="us-east-1" 
# AWS_PROFILE="default" 

set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${GREEN}--- Iniciando Despliegue de Ponchoneta Fútbol ---${NC}"

# --- Paso 1: Crear la VPC ---
echo -e "\n${YELLOW}Paso 1: Creando la VPC (ponchoneta-vpc)...${NC}"
aws cloudformation deploy \
  --template-file cloudformation/vpc.yaml \
  --stack-name ponchoneta-vpc \
  --capabilities CAPABILITY_NAMED_IAM
echo -e "${GREEN}VPC creada exitosamente.${NC}"

VPC_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaVPC'].OutputValue" --output text)
SUBNET1=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet1'].OutputValue" --output text)
SUBNET2=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet2'].OutputValue" --output text)

if [ -z "$VPC_ID" ] || [ -z "$SUBNET1" ] || [ -z "$SUBNET2" ]; then echo -e "${RED}Error VPC outputs. Abort.${NC}"; exit 1; fi
echo "VPC ID: $VPC_ID, Subnet1: $SUBNET1, Subnet2: $SUBNET2"

# --- Paso 2: Crear los grupos de seguridad ---
echo -e "\n${YELLOW}Paso 2: Creando Grupos de Seguridad (ponchoneta-sg)...${NC}"
aws cloudformation deploy \
  --template-file cloudformation/security-groups.yaml \
  --stack-name ponchoneta-sg \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPCID=$VPC_ID
echo -e "${GREEN}Grupos de Seguridad creados exitosamente.${NC}"

APP_SG_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaAppSecurityGroup'].OutputValue" --output text)
RDS_SG_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaRDSSecurityGroup'].OutputValue" --output text)
ALB_SG_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaALBSecurityGroup'].OutputValue" --output text)

if [ -z "$APP_SG_ID" ] || [ -z "$RDS_SG_ID" ] || [ -z "$ALB_SG_ID" ]; then echo -e "${RED}Error SG IDs. Abort.${NC}"; exit 1; fi
echo "App SG ID: $APP_SG_ID, RDS SG ID: $RDS_SG_ID, ALB SG ID: $ALB_SG_ID"

# --- Paso 3: Crear la base de datos RDS MySQL ---
echo -e "\n${YELLOW}Paso 3: Creando Base de Datos RDS (ponchoneta-db)...${NC}"
DB_NAME="ponchonetaDB"
DB_USER="admin"
read -sp "Ingresa contraseña para el usuario '$DB_USER' de la base de datos RDS: " DB_PASSWORD; echo

aws cloudformation deploy \
  --template-file cloudformation/rds.yaml \
  --stack-name ponchoneta-db \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID Subnet1=$SUBNET1 Subnet2=$SUBNET2 DBName=$DB_NAME DBUsername=$DB_USER DBPassword="$DB_PASSWORD" AppSecurityGroupForDBAccess=$APP_SG_ID RDSSecurityGroup=$RDS_SG_ID
echo -e "${GREEN}Base de Datos RDS creada exitosamente.${NC}"

DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ponchoneta-db --query "Stacks[0].Outputs[?OutputKey=='PonchonetaDBEndpoint'].OutputValue" --output text)
if [ -z "$DB_ENDPOINT" ]; then echo -e "${RED}Error RDS endpoint. Abort.${NC}"; exit 1; fi
echo "RDS Endpoint: $DB_ENDPOINT"

# --- Paso 4: Crear el Application Load Balancer (ALB) ---
echo -e "\n${YELLOW}Paso 4: Creando Application Load Balancer (ponchoneta-alb)...${NC}"
aws cloudformation deploy \
  --template-file cloudformation/alb.yaml \
  --stack-name ponchoneta-alb \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID Subnet1=$SUBNET1 Subnet2=$SUBNET2 ALBSecurityGroup=$ALB_SG_ID
echo -e "${GREEN}Application Load Balancer creado exitosamente.${NC}"

TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name ponchoneta-alb --query "Stacks[0].Outputs[?OutputKey=='PonchonetaTargetGroup'].OutputValue" --output text)
ALB_DNS_NAME=$(aws cloudformation describe-stacks --stack-name ponchoneta-alb --query "Stacks[0].Outputs[?OutputKey=='PonchonetaALBDNS'].OutputValue" --output text)

if [ -z "$TARGET_GROUP_ARN" ] || [ -z "$ALB_DNS_NAME" ]; then echo -e "${RED}Error ALB outputs. Abort.${NC}"; exit 1; fi
echo "Target Group ARN: $TARGET_GROUP_ARN, ALB DNS: http://$ALB_DNS_NAME"

# --- Paso 5: Crear Auto Scaling Group con EC2 ---
echo -e "\n${YELLOW}Paso 5: Creando Auto Scaling Group y EC2 (ponchoneta-app)...${NC}"
# EXISTING_INSTANCE_PROFILE_NAME="EMR_EC2_DefaultRole" # Ya no se necesita si se elimina del YAML

aws cloudformation deploy \
  --template-file cloudformation/ec2-autoscaling.yaml \
  --stack-name ponchoneta-app \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    VPC=$VPC_ID \
    Subnet1=$SUBNET1 \
    Subnet2=$SUBNET2 \
    AppSecurityGroup=$APP_SG_ID \
    TargetGroup=$TARGET_GROUP_ARN \
    DBEndpoint=$DB_ENDPOINT \
    DBName=$DB_NAME \
    DBUser=$DB_USER \
    DBPasswordValue="$DB_PASSWORD" \
    # ExistingInstanceProfileName=$EXISTING_INSTANCE_PROFILE_NAME # <-- Parámetro quitado
echo -e "${GREEN}Auto Scaling Group y EC2 creados exitosamente.${NC}"

echo -e "\n${GREEN}--- ¡DESPLIEGUE COMPLETO! ---${NC}"
echo -e "La aplicacion deberia estar disponible en unos minutos en: ${YELLOW}http://$ALB_DNS_NAME${NC}"
echo -e "Espera a que las instancias EC2 inicien y se registren en el Target Group."