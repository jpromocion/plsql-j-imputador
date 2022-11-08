# Imputador
Imputador de horas en api fuifi en plsql

 * v1.3: Solventa la problem�tica ante la modificaci�n de fuifi para impedir la imputaci�n sino se ha visitado la web/app para recibir los 10 puntos de recompensa. NOTA: lleva nuevo par�metro en el database.sql.
 * v1.4: Actualizaci�n cambio de dominio a laberitapp.com. Ahora la app esta en "https://laberitapp.com/" y se revisa el dominio principal de la API de invocaciones.

## Requisitos

Se requiere al menos una Oracle 12c, dado que hace uso de las funcionalidades a�adidas para extracci�n de JSON.

NOTA: Testeado en una Oracle 18c (18.3.0 Enterprise Edition) instalada por Docker oficial de Oracle https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance
NOTA: Tambi�n se prueba con una Oracle Autonomus Database de Oracle Cloud.

## Installation

Crea un esquema, por ejemplo "HR" con al menos los siguientes privilegios:

``` sql
CREATE USER HR IDENTIFIED BY hr;
GRANT CONNECT TO HR;
GRANT CREATE SESSION TO HR;
GRANT UNLIMITED TABLESPACE TO HR;
GRANT EXECUTE ON SYS.UTL_HTTP TO HR;
GRANT create procedure TO HR;
GRANT create table TO HR;
```

Con el usuario sys, conectado como sysdba debe crearse la ACL necesaria para conectar a la api de fuifi. Ejemplo:

``` sql
BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
   acl          => 'laberitapp.xml',
   description  => 'Permissions to access https://laberitapp.com',
   principal    => 'HR',
   is_grant     => TRUE,
   privilege    => 'connect');
  COMMIT;
END;
/

--Add a privilege to Access Control List
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
   acl          => 'laberitapp.xml',
   principal    => 'HR',
   is_grant     => TRUE,
   privilege    => 'connect',
   position     => null);
  COMMIT;
END;
/


--Assign a network host to Access Control List
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
   acl          => 'laberitapp.xml',
   host         => 'laberitapp.com');
  COMMIT;
END;
/
```
NOTA: Sustituir esquema "HR" por el que se utilice para instalar nuestro proyecto.

Para crear los componentes necesarios en nuestro esquema creado (en el ejemplo "HR"), lanzamos el script de inicializacion y la compilacion del paquete "imputador":
```
@init/database.sql
@src/imputador.pks
@src/imputador.pkb
```

Durante su ejecuci�n se pediran 3 par�metros a rellenar:
 * user: Tu usuario de la API fuifi
 * pass: Tu password de la API fuifi
 * domain: La organizaci�n de la API fuifi. Posteriormente la organizaci�n ha sido ocultado, pero la siguen gestionando, solo que ahora el valor es fijo a "laberit".


**IMPORTANTE: El siguiente paso para wallet se ha detectado innecesario si se utiliza una Oracle Autonomus Database de Oracle Cloud.**
Dado que la API REST de fuifi va por https, es necesario configurar un wallet de certificados en el servidor de la BBDD, e incluir en el el contenedor el certificado ra�z importado de la url https://api.fuifi.com/. Por ejempo, sobre la bbdd testeada del Docker 18c (Siendo USERTrustRSACertificationAuthority.crt donde se importo el certificado raiz):
```
mkdir -p /opt/oracle/admin/ORCLCDB/wallet
orapki wallet create -wallet /opt/oracle/admin/ORCLCDB/wallet -pwd WalletPasswd123 -auto_login
orapki wallet add -wallet /opt/oracle/admin/ORCLCDB/wallet -cert /tmp/USERTrustRSACertificationAuthority.crt -trusted_cert -pwd WalletPasswd123
```
NOTA: mas informaci�n al respecto en https://oracle-base.com/articles/misc/utl_http-and-ssl y https://apex.oracle.com/pls/apex/germancommunities/apexcommunity/tipp/6121/index-en.html.

Si se utiliza una ruta de contenedor de certificado y un password distinto, el mismo debe ser actualizado en la tabla creada en los scripts de inicializaci�n de nuestro esquema "CONFIGURATION":
  * El par�metro "WALLE" contiene la ruta de localizaci�n del contenedor de certificados. Defecto es "/opt/oracle/admin/ORCLCDB/wallet".
  * El par�metro "WALPS" contiene la contrase�a de acceso al contenedor de certificados. Defecto es "WalletPasswd123".



## Utilizaci�n:

Consultar las imputaciones de los �ltimos N d�as (el valor por defecto de N es 15):
``` sql
--Ultimos 15 dias
set serveroutput on
declare
begin
  imputador.getImputationsWrapper();
end;
/

--Ultimos 30 dias
set serveroutput on
declare
begin
  imputador.getImputationsWrapper(30);
end;
/
```

Ejemplo de salida:
```
�ltimas 5 imputaciones
----------------------------------------------
Fecha       Inicio   Fin      Tiempo Efec.
----------  -------  -------  ------------
19/11/2019  07:00    14:00    07:00
18/11/2019  07:00    14:00    07:00
15/11/2019  07:00    14:00    07:00
14/11/2019  07:00    14:00    07:00
13/11/2019  07:03    20:03    12:00
```

Para realizar una imputaci�n existen dos mecanismos
  * Especificar un conjunto de dias con sus imputaciones concretas:

  ``` sql
  --imputar 2 dias
  set serveroutput on
  declare
    tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
    dia VARCHAR2(10);
  begin

    tDiasImputar.EXTEND(2);
    --dia 1
    dia := '20/11/2019';
    tDiasImputar(1).DATEIM := TO_DATE(dia,'DD/MM/YYYY');
    tDiasImputar(1).STARTTIME := TO_DATE(dia || ' 08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).ENDTIME := TO_DATE(dia || ' 21:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).TIMEEFECTIVE := TO_DATE(dia || ' 12:00','DD/MM/YYYY HH24:MI');
    --dia 2
    dia := '21/11/2019';
    tDiasImputar(2).DATEIM := TO_DATE(dia,'DD/MM/YYYY');
    tDiasImputar(2).STARTTIME := TO_DATE(dia || ' 08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(2).ENDTIME := TO_DATE(dia || ' 15:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(2).TIMEEFECTIVE := TO_DATE(dia || ' 07:00','DD/MM/YYYY HH24:MI');
    --dias N.....

    imputador.setImputationsWrapper(tDayImputations => tDiasImputar);
  end;
  /
  ```

  * Especificar un rango de fechas, y un conjunto de d�as modelo para los 5 dias laborales, imputandose en todo el periodo indicado, haciendo uso de la imputaci�n del d�a modelo de semana:

  ``` sql
  set serveroutput on
  declare
    tDiasModelo Imputador.T_MODELDAYS  := Imputador.T_MODELDAYS();
  begin

    tDiasModelo.EXTEND(5);
    --dia 1 -> lunes (el dia en si que se carge en el DATE no importa, utiliza la hora)
    tDiasModelo(1).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(1).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(1).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00', 'DD/MM/YYYY HH24:MI');
    --dia 2 -> martes
    tDiasModelo(2).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(2).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(2).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00', 'DD/MM/YYYY HH24:MI');
    --dia 3 -> miercoles
    tDiasModelo(3).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(3).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '21:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(3).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '12:00', 'DD/MM/YYYY HH24:MI');
    --dia 4 -> jueves
    tDiasModelo(4).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(4).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(4).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00', 'DD/MM/YYYY HH24:MI');
    --dia 5 -> viernes
    tDiasModelo(5).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(5).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00', 'DD/MM/YYYY HH24:MI');
    tDiasModelo(5).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00', 'DD/MM/YYYY HH24:MI');

    imputador.setImputationsWrapper(startDate => TO_DATE('20/11/2019','DD/MM/YYYY'),
                                    endDate => TO_DATE('21/11/2019','DD/MM/YYYY'),
                                    tModelDays => tDiasModelo);
  end;
  /
  ```

Ejemplo de salida con 1 dia imputado:
```
D�a 20/11/2019 -> success - 200 - Saved
```

Ejemplo de rechazo de una imputaci�n (por ejemplo, si el d�a ya est� imputado):
```
[ERROR]: Received non-OK response: 400 Bad Request
```

Adicionalmente se a�aden los parametros de invocaci�n del imputador "randomTime" y "randomEfective" (por defecto no activados):
  * "randomTime": Sobre la hora de entrada y salida, a�ade/decrementa aleatoriamente un valor de entre 1 a 5 minutos (aportar realismo). NOTA: En caso de provocarse un incremento del tiempo real sobre el efectivo rellenado, se corrige autom�ticamente el efectivo para evitar descuadrar.
  * "randomEfective": Adicionalmente, sobre el tiempo efectivo a imputar, decrementa un valor aleatorio de entre 1-15 minutos (aportar realismo).
Ejemplo:
``` sql
set serveroutput on
declare
  tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
  DIA CONSTANT VARCHAR2(10) := '21/11/2019';
begin

  tDiasImputar.EXTEND(1);
  --dia 2
  tDiasImputar(1).DATEIM := TO_DATE(DIA,'DD/MM/YYYY');
  tDiasImputar(1).STARTTIME := TO_DATE(DIA || ' 08:00','DD/MM/YYYY HH24:MI');
  tDiasImputar(1).ENDTIME := TO_DATE(DIA || ' 15:00','DD/MM/YYYY HH24:MI');
  tDiasImputar(1).TIMEEFECTIVE := TO_DATE(DIA || ' 07:00','DD/MM/YYYY HH24:MI');
  --dias N.....

  imputador.setImputationsWrapper(tDayImputations => tDiasImputar, randomTime => TRUE, randomEfective => TRUE);
end;
/
```


NOTA: �sese bajo responsabilidad personal.


## Unit test
Testeado con utPlsql version 3 (http://utplsql.org/utPLSQL/).
Ejecutar:
``` sql
set serveroutput on
begin
  ut.run('hr:test.plsql.j.imputador');
end;
/
```
NOTA: reemplazar "hr" por el esquema donde se haya creado

!!!CUIDADO!!!: El entorno es producci�n, la prueba intentar� imputar en el d�a actual.


## Documentaci�n adicional
Se genera documentaci�n del fuente con PlDoc (http://pldoc.sourceforge.net/maven-site/). La documentaci�n auto-generada se localiza en "pldoc".

Ejecuci�n de la generaci�n:
```
#Windows
call pldoc.bat -doctitle 'plsql-j-imputador' -d pldoc -inputencoding ISO-8859-15 src/*.*

#Linux:
pldoc.sh -doctitle \"plsql-j-imputador\" -d pldoc -inputencoding ISO-8859-15 src/*.*
```
