+++
title = "Desplegando una app de Flask"
date = Date(2021, 12, 01)
+++

Desplegar una aplicación de *Flask* es una tarea sencilla, básicamente esto consiste en lo siguiente:

- Servir la aplicación mediante un servidor más robusto que el que viene cargado por default en *Flask*.
- Habilitar la app como un servicio del sistema para garantizar que se encuentre siempre "encendida".
- Agregar las reglas necesarias al *firewall*(si es que se cuenta con uno) para permitir las conexiones entrantes.

A manera de ejemplo supongamos que nuestra aplicación es de la forma siguiente

**server.py**
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Hola mundo, estoy vivo!'
```

El primer paso a realizar es instalar un servidor más robusto que el que viene por default con *Flask*, una opción sencilla es [gunicorn](https://gunicorn.org/). Para esto debemos activar el ambiente virtual de nuestra aplicación(tener un ambiente virtual no es estrictamente necesario, sin embargo, vuelve todo más limpio y fácil de mantener) y posteriormente instalar *gunicorn* mediante `pip` 

```bash
source venv/bin/activate
pip install gunicorn
```
Una vez instalado *gunicorn* es posible servir nuestra aplicación mediante él, esto se consigue a través del siguiente comando

```bash
gunicorn --bind 0.0.0.0:5000 server:app --workers=2
```

En lo anterior lo que hemos hecho es servir nuestra aplicación `app` dentro del script de python `server.py` a través del puerto 5000 y empleando 2 procesos para atender las peticiones a esta aplicación. Si todo es correcto debemos ver el siguiente mensaje indicando que el servidor de *gunicorn* está corriendo y sirviendo correctamente nuestra aplicación

![gunicorn](/assets/gunicorn_init.png)

Una vez que sabemos que nuestra aplicación funciona correctamente con *gunicorn*, es momento de generar los archivos de configuración para habilitar nuestra aplicación como un servicio de *Linux*, para esto editamos el siguiente archivo(o lo creamos) 

**/etc/systemd/system/myapp.service**
```bash
[Unit]
Description=Este es un servicio para servir a mi app de Flask.
After=network.target

[Service]
User=usuario
Group=grupo
WorkingDirectory=/ruta_app
Environment="PATH=/ruta_al_venv_app"
ExecStart=/ruta_app/venv/bin/guinicorn --workers=2 --bind 0.0.0.0:5000 server:app

[Install]
WantedBy=multi-user.target
```
En donde el significado de algunas opciones es:

- **After**: indica al sistema cuándo iniciar esta unidad de servicio, en este caso estamos ordenando que el servicio se "levante" posterior a haber habilitado los servicios de networking.
- **User/Group**: define mediante qué usuario/grupo será lanzado el servicio, si se omiten, por default se lanza mediante `root`.
- **WorkingDirectory**: ruta en donde se encuentra nuestra app.
- **Environment**: estamos usando esta opción para exportar la variable PATH, la cuál indicará al sistema en dónde buscar los paquetes necesarios que nuestra aplicación podría necesitar, en este caso queremos que apunte a la carpeta con los binarios del entorno virtual de nuestra app(.../venv/bin).
- **ExecStart**: es el comando que el sistema ejecutará al levantar este servicio, en nuestro caso queremos que se ponga en marcha el servidor de *gunicorn*.
- **WantedBy**: esto sirve para que nuestra app inicie cuando se inicia el sistema, para esto hacemos que este servicio sea requerido por `multi-user.target` el cual es un conjunto de servicios que se inician cuando el sistema se "levanta", dicho de otro modo `multi-user.target` es un estado del sistema en el cuál ya se encuentra listo para operar. Generalmente se usa este target para indicar que el servicio debe "levantarse" al iniciar el sistema.

**Nota**: Si te interesa saber más acerca de *systemd* y las unidades de servicios, puedes encontrar información útil [aquí](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-managing_services_with_systemd-unit_files), también [aquí](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-Managing_Services_with_systemd#tabl-Managing_Services_with_systemd-Introduction-Units-Types) y en este [blog post](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files).


Habiendo configurado este archivo sólo nos hace falta habilitar e iniciar el servicio mediante `systemctl`

```bash
sudo systemctl start myapp
sudo systemctl enable myapp
```
Si todo está correcto, al ejecutar `systemctl myapp` deberíamos ver un mensaje como el siguiente

![myapp status](/assets/app_status.png)

Por último, sólo falta configurar el firewall(si es que el sistema tiene alguno instalado) para permitir las conexiones entrantes por el puerto sobre el cual montamos la aplicación, en este caso en particular hemos lanzado la aplicación sobre el puerto 5000, por lo que es suficiente ejecutar(si se cuenta con un firewall distinto a `ufw` necesitarás buscar las instrucciones apropiadas)

```bash
sudo ufw allow 5000
sudo ufw status
```
Tras ejecturar lo anterior estamos habilitando las conexiones a través del puerto 5000 y posteriormente listando todas las reglas que tiene definido el firewall, por lo que al ejecutar `sudo ufw status` deberíamos observar una pantalla como la siguiente

![ufw_status](/assets/ufw_status.png)

Aquí vemos como ha sido agregada a las reglas del firewall las conexiones por el puerto `5000`. Hecho esto podremos acceder a la app externamente visitando `http://ip_address:5000`.

Lo expuesto aquí es la manera más sencilla y rápida de poner "online" una app de *Flask*, aunque esto es funcional no es la mejor manera de hacerlo, pues esto requiere de abrir puertos extra para cada app que alojemos en el servidor, una mejor forma de hacer esto es poner a escuchar nuestra app a través de un *Unix socket* y posteriormente redireccionar el trafico de manera adecuada a este socket, de esta forma se podrían tener varias aplicaciones dentro del mismo servidor y sólo habilitar un puerto que escuche todas las conexiones. De este modo podríamos redirigir las peticiones al *socket* correcto dependiendo de qué recurso(app) se está solicitando(esto puede hacerse con Nginx y será parte de otro post). 

Fin.

