# Database migrator

## Docker Compose

El **docker-compose.yml** tendrá la siguiente forma:

```shell script
migrator:
  build: ./bin/migrator
  container_name: 'migrator'
  depends_on:
    - mysql # name of mysql container
  links:
    - mysql # name of mysql container
  volumes:
    - ${DOCUMENT_ROOT-../migrations}:/usr/src/app/migrations
  user: node
  working_dir: /usr/src/app
  entrypoint: npm
  command: start # starts npm
  environment:
    MYSQL_URL: mysql://USER:PASSWORD@SERVER/DATABASE
```
Donde `USER`, `PASSWORD` y `DATABASE` son los credenciales del container mysql, y `SERVER` el nombre el mismo.

También destacar la carpeta montada `migrations`, que es donde se generarán los tres ficheros que veremos más adelante, y que nos
servirá para lanzar un upgrade (o downgrade) de la base de datos.

## Script

La forma más sencilla de ejecutar las instrucciones de actualización de base es mediante un script que nos conecte al 
container donde está el migrator. Nótese que esto es solo para ayudarnos, podemos ejecutar los códigos manualmente de
forma análoga, cambiando la llamada al script por la conexión al container.

El script tendrá la siguiente forma:

**migrator.sh**
```shell script
#!/bin/bash -e

CMD=$@

SCRIPT=`realpath -s $0`
SCRIPTPATH=`dirname $SCRIPT`

cd ${SCRIPTPATH}/docker # route from script to docker folder
docker-compose run --rm patients-migrator run migrate ${CMD}

```
Donde `CONTAINER_NAME` es el nombre del contenedor donde se está ejecutando el Database Migrator.

### Generar nuevo .sql

Para generar un nuevo .sql aplicable, utilizaremos el comando:
```shell script
$ ./migrator.sh create EXAMPLE
```

Donde `EXAMPLE` es el nombre del .sql que queremos generar. Esto nos creará tres ficheros:

- `migrations/TIMESTAMP-EXAMPLE.js`: Se utiliza para determinar que hay que ejecutar el sql con este nombre
- `migrations/sqls/TIMESTAMP-EXAMPLE-up.sql`: Código sql a ejecutar para aplicar el cambio.
- `migrations/sqls/TIMESTAMP-EXAMPLE-down.sql`: Código sql a ejecutar para revertir el cambio.

Exceptuando el .js, los demás ficheros los crerá vacíos. Nosotros tenemos que encargarnos de añadir el código sql de
nuestro cambio en el fichero _up_, y de añadir el código sql para revertir dicho cambio en _down_ (si lo hubiese).

Como se puede observar, añade el `TIMESTAMP` al nombre de los ficheros, por lo que no hay que tener en cuenta el orden
alfabético para calcular el orden de ejecución. De hecho, podrían llamarse todos igual.


### Lanzar .sql pendientes

Para lanzar los .sql pendientes ejecutaremos:
```shell script
$ ./migrator.sh up
```

Esto añadirá todos los .sql que no hayan sido ejecutados previamente, y actualizará la tabla `migrations`. De esta 
forma no volverá a lanzar los mismos .sql en la próxima ejecución.


### Revertir cambios

Para revertir los .sql aplicados ejecutaremos:
```shell script
$ ./migrator.sh down
```

Con este comando, se ejecutarán los XXX-down.sql que haya guardados en la tabla `migrations`. Los aplicará en orden
inverso a como se insertaron (de más nuevo a más antiguo).