#!/bin/bash

set -euo pipefail

echo "🚀 Desplegando Ponchoneta E-commerce en AWS desde cero..."

# Clonar repo si no existe la carpeta
if [ ! -d "PonchonetaEcommerce" ]; then
  echo "Clonando repositorio..."
  git clone https://github.com/felipevelasco7/PonchonetaEcommerce.git
fi
cd PonchonetaEcommerce

# Función para obtener un output exportado de CloudFormation
get_stack_output() {
  local stack_name=$1
  local output_key=$2
  aws cloudformation describe-stacks --stack-name "$stack_name" --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" --output text
}

# 1. Crear VPC y subnets
echo "🔹 Paso 1: Crear VPC y subnets públicas..."
aws cloudformation deploy \
  --template-file cloudformation/vpc.yaml \
  --stack-name ponchoneta-vpc \
  --capabilities CAPABILITY_NAMED_IAM

# Obtener IDs de VPC y subnets
VPC_ID=$(get_stack_output ponchoneta-vpc PonchonetaVPC)
SUBNET1=$(get_stack_output ponchoneta-vpc PonchonetaPublicSubnet1)
SUBNET2=$(get_stack_output ponchoneta-vpc PonchonetaPublicSubnet2)

echo "VPC creada: $VPC_ID"
echo "Subnets: $SUBNET1, $SUBNET2"

# Validar subnets
if [ "$SUBNET1" == "$SUBNET2" ] || [ -z "$SUBNET1" ] || [ -z "$SUBNET2" ]; then
  echo "ERROR: Subnets inválidas o iguales. Revisa la creación de la VPC."
  exit 1
fi

# 2. Crear Security Groups
echo "🔹 Paso 2: Crear Security Groups..."
aws cloudformation deploy \
  --template-file cloudformation/security-groups.yaml \
  --stack-name ponchoneta-sg \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID

# Obtener ID Security Group ALB (ajusta el nombre según plantilla)
ALB_SG=$(get_stack_output ponchoneta-sg PonchonetaALBSecurityGroup)
if [ -z "$ALB_SG" ]; then
  echo "ERROR: No se pudo obtener el Security Group para ALB."
  exit 1
fi
echo "Security Group ALB: $ALB_SG"

# 3. Crear RDS
echo "🔹 Paso 3: Crear base de datos RDS MySQL..."
read -s -p "Ingresa la contraseña para la base de datos RDS: " RDS_PASSWORD
echo

aws cloudformation deploy \
  --template-file cloudformation/rds.yaml \
  --stack-name ponchoneta-rds \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID DBPassword=$RDS_PASSWORD

# 4. Crear ALB
echo "🔹 Paso 4: Crear Application Load Balancer (ALB)..."
aws cloudformation deploy \
  --template-file cloudformation/alb.yaml \
  --stack-name ponchoneta-alb \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Subnet1=$SUBNET1 Subnet2=$SUBNET2 ALBSecurityGroup=$ALB_SG

# Obtener Target Group ARN para paso siguiente
TARGET_GROUP_ARN=$(get_stack_output ponchoneta-alb PonchonetaTargetGroup)
if [ -z "$TARGET_GROUP_ARN" ]; then
  echo "ERROR: No se pudo obtener el ARN del Target Group."
  exit 1
fi
echo "Target Group ARN: $TARGET_GROUP_ARN"

# 5. Crear Auto Scaling Group con EC2
echo "🔹 Paso 5: Crear Auto Scaling Group con instancias EC2..."

aws cloudformation deploy \
  --template-file cloudformation/autoscaling.yaml \
  --stack-name ponchoneta-app \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      VPC=$VPC_ID \
      Subnet1=$SUBNET1 \
      Subnet2=$SUBNET2 \
      SecurityGroup=$ALB_SG \
      TargetGroupARN=$TARGET_GROUP_ARN

echo "✅ Despliegue completado exitosamente."
echo "Puedes acceder a la aplicación vía el DNS del ALB."

ALB_DNS=$(get_stack_output ponchoneta-alb PonchonetaALBDNS)
echo "URL: http://$ALB_DNS"

exit 0
