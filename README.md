# Ponchoneta Fútbol - Despliegue Completo en AWS (CloudFormation + Auto Scaling + ALB + RDS)

Este README contiene TODOS los comandos para desplegar tu proyecto desde cero en AWS con CloudFormation, listos para copiar y pegar en AWS CloudShell.

---

## Requisitos

- AWS CLI configurada (ejecuta `aws configure` si no la tienes)
- Clonado del repositorio no necesario, el EC2 lo hará

---

## Paso 1: Crear la VPC con dos subredes públicas

```bash
aws cloudformation deploy \
  --template-file cloudformation/vpc.yaml \
  --stack-name ponchoneta-vpc \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## Paso 2: Crear los grupos de seguridad

Obtén el ID de la VPC:

```bash
VPC_ID=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaVPC'].OutputValue" --output text)
```

Despliega grupos de seguridad:

```bash
aws cloudformation deploy \
  --template-file cloudformation/security-groups.yaml \
  --stack-name ponchoneta-sg \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID
```

---

## Paso 3: Crear la base de datos RDS MySQL

Obtén los IDs de las subredes:

```bash
SUBNET1=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet1'].OutputValue" --output text)
SUBNET2=$(aws cloudformation describe-stacks --stack-name ponchoneta-vpc --query "Stacks[0].Outputs[?OutputKey=='PonchonetaPublicSubnet2'].OutputValue" --output text)
```

Ejecuta el despliegue pidiendo contraseña:

```bash
read -sp "Ingresa contraseña para la base de datos RDS: " DB_PASSWORD
echo

aws cloudformation deploy \
  --template-file cloudformation/rds.yaml \
  --stack-name ponchoneta-db \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VPC=$VPC_ID Subnet1=$SUBNET1 Subnet2=$SUBNET2 DBPassword=$DB_PASSWORD
```

---

## Paso 4: Crear el Application Load Balancer (ALB)

Obtén los grupos de seguridad:

```bash
APP_SG=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaAppSecurityGroup'].OutputValue" --output text)
ALB_SG=$(aws cloudformation describe-stacks --stack-name ponchoneta-sg --query "Stacks[0].Outputs[?OutputKey=='PonchonetaALBSecurityGroup'].OutputValue" --output text)
```

Despliega el ALB:

```bash
aws cloudformation deploy \
  --template-file cloudformation/alb.yaml \
  --stack-name ponchoneta-alb \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Subnet1=$SUBNET1 Subnet2=$SUBNET2 ALBSecurityGroup=$ALB_SG
```

---

## Paso 5: Crear Auto Scaling Group con EC2

Obtén endpoint RDS y Target Group ARN:

```bash
DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ponchoneta-db --query "Stacks[0].Outputs[?OutputKey=='PonchonetaDBEndpoint'].OutputValue" --output text)
TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name ponchoneta-alb --query "Stacks[0].Outputs[?OutputKey=='PonchonetaTargetGroup'].OutputValue" --output text)
```

Despliega Auto Scaling Group:

```bash
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
```

---

## Verificar aplicación

- Ve a EC2 > Load Balancers en la consola AWS.
- Copia el DNS público del ALB.
- Ábrelo en navegador, ejemplo:

```
http://PonchonetaALB-xyz.us-east-1.elb.amazonaws.com
```

---

## Notas

- La AMI usada en EC2 es para us-east-1 (Amazon Linux 2). Cambiar si usas otra región.
- Asegúrate que el archivo `backend/config/sequelize.js` tenga `localhost` como host para que el reemplazo del endpoint funcione.
- El repositorio debe ser accesible para EC2.