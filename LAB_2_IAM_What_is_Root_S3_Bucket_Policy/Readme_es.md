# Que es Root?

Especificamente, que significa lo siguiente, cuando se utiliza como Principal en una politica de recurso de IAM?

```
"Principal": {"AWS": ["arn:aws:iam::111122223333:root]}
```

## Introduccion
Este lab examina la diferencia entre las politicas de IAM y las basadas en recursos de AWS. Especificamente, queremos entender
la logica de evaluacion de politicas para los baldes de S3 que permiten el acceso entre cuentas. Para un recordatorio de lo basico de IAM, ver
[Logica de Evaluacion de Politicas de Referencia](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html),
lo cual es valido para cuando el Principal de IAM y el recurso de S3 estan en la misma cuenta de AWS.
 
Para resumir, si una accion esta permitida por una politica basada en identidad, una politica basada en un recurso, o ambas,
entonces AWS permite la accion. Un "Deny" explicito en cualquiera de estas politicas sobreescribe ese permiso.

La situacion cambia para el [accesso entre cuentas](https://aws.amazon.com/premiumsupport/knowledge-center/cross-account-access-s3/).
En este caso, el acceso tiene que ser explicitamente permitido tanto en la politica de acceso del Principal como en la politica del recurso.
Desafortunadamente, el link no menciona el "problema del diputado confundido" para el acceso entre cuentas, el cual ocurre cuando la cuenta
confiada es un vendedor tercero de SaaS (Software como un Servicio, en ingles). Como resultado de esto, muchos vendedores que operan en
baldes de S3 de sus clientes, lo hacen inseguramente


Para este lab, asumiremos que ambas cuentas de AWS son de la misma entidad y dejaremos los problemas de diputado
confundido para el Lab 4. Otorgar permisos a Principals en una cuenta de AWS externa se puede hacer de dos maneras -
Acceso Directo (Direct Access) y Asumir Rol (Assume Role)


Alternativamente, el acceso entre cuentas se podria otorgar en una politica de recurso tal como la siguiente politica de balde.


demo-policy.json
```.json
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddCrossAccountPutPolicy",
      "Effect":"Allow",
      "Principal": {"AWS": ["arn:aws:iam::111122223333:root","arn:aws:iam::444455556666:root"]},
      "Action":["s3:PutObject","s3:GetObject","s3:ListBucket"],
      "Resource":["arn:aws:s3:::mybucket/*", "arn:aws:s3:::mybucket"],
        "Condition": {
          "IpAddress": {
            "aws:SourceIp": [
              "54.240.143.0/24",
              "54.240.144.0/24"
            ]
          }
        }
      }
    ]
  }
```

Pregunta:

* Podemos modificar las politicas de balde desde IPs que no hayan sido aprobadas? (plano de control, comandos que no sean del plano de datos)


### Asumir Rol (Assume Role)
El acceso a traves de Asumir un Rol requiere añadir declaraciones 
como la siguiente en la politica de confianza de la seccion de assume-role de un rol.

Politica de confianza de un rol de IAM
```
"Principal":{"AWS":"arn:aws:iam::AWSTargetAccountID:root"}
```

## Instalacion
Para probar esto, vas a necesitar dos cuentas donde seas admin, dado que necesitaras la habilidad para crear usuarios,
roles y politicas. Si un instructor quisiera correr esto en una clase sin otorgar derechos de administrador plenos,
entonces podria establecerse un limite o perimetro a los permisos, que permita la creacion de roles y usuarios,
pero no la de politicas, siguiendo la [documentacion de AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html).


```
cp demo-vars.txt vars.txt
session_random=${RANDOM}-${RANDOM}
echo "mybucket=mybucket-$session_random" >> vars.txt
```

replace the RHS of the following in 
vars.txt
```.env
internal_account=111122223333 
external account=444455556666 
cidr_1=54.240.143.0/24
cidr_2=54.240.144.0/24
```

```
.bash
source vars.txt
for file in `ls demo-*.json`; do
output_name=`echo $file | sed 's|demo-||'`
cat $file \
| sed "s|111122223333|$internal_account|g" \
| sed "s|444455556666|$external_account|g" \
| sed "s|54.240.143.0/24|$cidr_1|g" \
| sed "s|54.240.144.0/24|$cidr_2|g" \
| sed "s|mybucket|$mybucket|g" \
| sed "s|session_random|$session_random|g" \
> $output_name
done
```
Conceder acceso a cualquier credencial de AWS asociada con cualquiera de nuestras 2 cuentas,
reemplazando policy.json por assume-role-for-mybucket.json


```
.bash
aws s3api create-bucket --bucket $mybucket
aws s3api put-bucket-policy --bucket $mybucket --policy file://s3-resource-cross-account-policy.json
```

aws s3api get-bucket-policy --bucket $mybucket

aws iam list-attached-user-policies --user-name s3reader

aws --profile pbeta-s3reader s3api put-object --bucket $mybucket --key can-internal-readonly-role-put-object/test1 --body Readme.md

aws --profile pdelta iam create-user --user-name s3tester1-$session_random

aws --profile pdelta iam create-access-key --user-name s3tester1-$session_random
echo "place the aws_access_key_id and aws_secret_access_key in ~/.aws/credentials with profile name [s3tester1-ext]."

aws --profile pdelta iam create-role --role-name s3tester1-role-$session_random --assume-role-policy-document file://assume-role-policy-for-s3tester-extern.json

aws iam create-role --role-name s3reader-$session_random --assume-role-policy file://assume-role-policy-for-s3reader.json

Preguntas:

1. Puede algun usuario...? 
https://docs.aws.amazon.com/IAM/latest/UserGuide/intro-structure.html
