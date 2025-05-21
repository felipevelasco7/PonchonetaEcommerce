# Ponchoneta Fútbol - Despliegue Completo en AWS (CloudFormation + Auto Scaling + ALB + RDS)

Este proyecto despliega una aplicación de comercio electrónico full-stack en AWS utilizando CloudFormation, un Application Load Balancer, Auto Scaling Group para instancias EC2, y una base de datos RDS MySQL.

---

## Requisitos Previos

1.  **AWS CLI Configurada:** Asegúrate de tener AWS CLI instalado y configurado con credenciales que tengan permisos para crear los recursos necesarios (VPC, EC2, SGs, RDS, ALB, IAM Roles, CloudFormation).
    ```bash
    aws configure
    ```
    El script y las plantillas por defecto usan la región `us-east-1`. Si necesitas usar otra región, modifica el script `deploy-ponchoneta.sh` (la variable `AWS_REGION`) y verifica las AMIs en `cloudformation/ec2-autoscaling.yaml`.

2.  **Repositorio Git Público:** El repositorio de la aplicación backend y frontend (`https://github.com/felipevelasco7/PonchonetaEcommerce.git`) debe ser **PÚBLICO** para que las instancias EC2 puedan clonarlo durante el UserData.

3.  **Backend Preparado:**
    *   El archivo `backend/app.js` debe estar configurado para leer las variables de entorno `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, y `PORT` (el UserData crea un archivo `.env` con estos valores). Se recomienda usar el paquete `dotenv`.
    *   Debe implementar un endpoint `/health` que responda `HTTP 200 OK` para los health checks del ALB.
    *   Se recomienda que el backend sirva los archivos estáticos del frontend para que las rutas relativas en el JavaScript del frontend funcionen correctamente.

---

## Despliegue Automatizado

Este proyecto incluye un script para automatizar la creación de todos los stacks de CloudFormation en el orden correcto.

**Pasos para el Despliegue:**

1.  **Clona este repositorio (si aún no lo has hecho):**
    *(Si ya tienes los archivos, omite este paso)*
    ```bash
    # git clone <URL_DE_ESTE_REPOSITORIO_CON_LAS_PLANTILLAS_CFN_Y_SCRIPT>
    # cd PonchonetaEcommerce/
    ```

2.  **Hacer el script ejecutable:**
    ```bash
    chmod +x deploy-ponchoneta.sh
    ```

3.  **Ejecutar el script de despliegue:**
    ```bash
    ./deploy-ponchoneta.sh
    ```
    El script te pedirá que ingreses la contraseña para el usuario `admin` de la base de datos RDS.

4.  **Monitorear el Despliegue:**
    *   El script mostrará el progreso en la terminal.
    *   También puedes monitorear la creación de los stacks en la consola de AWS CloudFormation.
    *   El script imprimirá el DNS del Application Load Balancer al final.

---

## Verificar la Aplicación

1.  Una vez que el script `deploy-ponchoneta.sh` haya finalizado, espera unos minutos para que:
    *   Las instancias EC2 se inicien completamente.
    *   El script UserData en las instancias EC2 clone el repositorio, instale dependencias e inicie la aplicación.
    *   Las instancias se registren como saludables en el Target Group del Application Load Balancer.

2.  Copia el **DNS del ALB** que el script muestra al final (o encuéntralo en la consola de AWS > EC2 > Load Balancers > selecciona `PonchonetaALB` > copia el "DNS name").

3.  Abre el DNS en tu navegador web. Ejemplo:
    ```
    http://ponchonetaalb-xxxxxxxxx.us-east-1.elb.amazonaws.com
    ```

4.  Deberías ver la página principal de la aplicación Ponchoneta Fútbol.
    *   Navega a `/register.html` para crear un nuevo usuario.
    *   Prueba otras funcionalidades.

---

## Solución de Problemas Comunes

-   **Errores del Script o CloudFormation:** Revisa la salida de la terminal. Si un stack de CloudFormation falla, ve a la consola de AWS CloudFormation, selecciona el stack fallido y revisa la pestaña "Events" para mensajes de error detallados.
-   **UserData / Aplicación no inicia en EC2:**
    -   **Conexión:** Si es posible, usa EC2 Instance Connect o Session Manager (requiere que el rol IAM de la instancia tenga `AmazonSSMManagedInstanceCore`).
    -   **Logs de UserData:** En la instancia, revisa `sudo cat /var/log/user-data.log` (o `sudo cat /var/log/cloud-init-output.log`).
    -   **Logs de PM2:** `pm2 list` y `pm2 logs ponchoneta-backend`.
    -   **CloudWatch Logs:** Si el CloudWatch Agent está configurado, busca los grupos de logs (`/ec2/ponchoneta/*`).
-   **Instancias no pasan Health Check del ALB:**
    -   Verifica el endpoint `/health` en tu backend.
    -   Confirma la configuración de los Security Groups.
    -   Asegúrate que la aplicación Node.js corre en el puerto `3000`.
    -   Revisa los logs de la aplicación por errores de conexión a la BD.

---

## Notas Adicionales Importantes

-   **Región AWS:** Por defecto `us-east-1`. Si cambias la región en el script, asegúrate que la AMI SSM en `cloudformation/ec2-autoscaling.yaml` (`ImageId: '{{resolve:ssm:...}}'`) sea válida para esa nueva región o usa una AMI ID hardcodeada.
-   **Permisos IAM:** El rol de instancia (`PonchonetaInstanceRole`) necesita permisos para `ssm:GetParameter` y `CloudWatchAgentServerPolicy`. Verifica que tu cuenta/rol de AWS Academy Sandbox lo permita.
-   **Costos:** Los recursos de AWS incurren en costos. Elimina los stacks cuando no los necesites.
-   **Seguridad de Contraseña de BD:** El script `UserData` escribe la contraseña de la BD en un archivo `.env` en la instancia EC2. Esto es aceptable para este ejercicio en un sandbox, pero para **producción**, debes usar **AWS Secrets Manager** para gestionar la contraseña de la base de datos de forma segura.

---

## Limpieza (Eliminar Todos los Recursos)

Para eliminar todos los recursos creados por este despliegue, puedes eliminar los stacks de CloudFormation. **Es crucial hacerlo en el orden inverso a su creación para evitar errores de dependencia.**

1.  **Opcional: Crear un script de limpieza `cleanup-ponchoneta.sh`:**
    ```bash
    #!/bin/bash
    set -e
    echo "Iniciando limpieza de stacks de Ponchoneta Fútbol..."

    STACKS_TO_DELETE=(
      "ponchoneta-app"
      "ponchoneta-alb"
      "ponchoneta-db"
      "ponchoneta-sg"
      "ponchoneta-vpc"
    )

    for stack_name in "${STACKS_TO_DELETE[@]}"; do
      echo "Verificando si el stack $stack_name existe..."
      if aws cloudformation describe-stacks --stack-name "$stack_name" > /dev/null 2>&1; then
        echo "Eliminando stack $stack_name..."
        aws cloudformation delete-stack --stack-name "$stack_name"
        echo "Esperando a que $stack_name se elimine completamente..."
        aws cloudformation wait stack-delete-complete --stack-name "$stack_name"
        echo "Stack $stack_name eliminado."
      else
        echo "Stack $stack_name no encontrado, omitiendo."
      fi
    done

    echo "Limpieza completada."
    ```
    Hazlo ejecutable: `chmod +x cleanup-ponchoneta.sh` y luego ejecútalo: `./cleanup-ponchoneta.sh`

2.  **Manualmente (si no usas el script de limpieza):**
    Elimina los stacks uno por uno desde la consola de CloudFormation o usando AWS CLI en este orden:
    ```bash
    # aws cloudformation delete-stack --stack-name ponchoneta-app
    # aws cloudformation wait stack-delete-complete --stack-name ponchoneta-app
    # aws cloudformation delete-stack --stack-name ponchoneta-alb
    # aws cloudformation wait stack-delete-complete --stack-name ponchoneta-alb
    # aws cloudformation delete-stack --stack-name ponchoneta-db
    # aws cloudformation wait stack-delete-complete --stack-name ponchoneta-db
    # aws cloudformation delete-stack --stack-name ponchoneta-sg
    # aws cloudformation wait stack-delete-complete --stack-name ponchoneta-sg
    # aws cloudformation delete-stack --stack-name ponchoneta-vpc
    # aws cloudformation wait stack-delete-complete --stack-name ponchoneta-vpc
    ```
    *Nota: La eliminación de la instancia RDS (`ponchoneta-db`) puede tardar más. Si tiene protección contra eliminación habilitada, deberás deshabilitarla primero.*

---