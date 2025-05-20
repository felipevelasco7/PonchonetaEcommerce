#!/bin/bash
# Actualiza paquetes y prepara ambiente
yum update -y

# Instala Node.js y MySQL client
curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
yum install -y nodejs git mysql

# Clona el repositorio de la aplicación
cd /home/ec2-user
git clone https://github.com/felipevelasco7/ponchonetaAWS.git
cd ecommerce-aws-deploy/backend

# Instala dependencias y lanza app
npm install
npm install pm2 -g
pm2 start app.js --name ecommerce
pm2 startup
pm2 save