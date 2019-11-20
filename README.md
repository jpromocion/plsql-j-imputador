# Imputador
Imputador de horas en api fuifi en plsql

## Requisitos

Se requiere al menos una Oracle 12c, dado que hace uso de las funcionalidades a�adidas para extracci�n de JSON.

NOTA: Testeado en una Oracle 18c (18.3.0 Enterprise Edition) instalada por Docker oficial de Oracle https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance

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
   acl          => 'apifuifi.xml',
   description  => 'Permissions to access https://api.fuifi.com',
   principal    => 'HR',
   is_grant     => TRUE,
   privilege    => 'connect');
  COMMIT;
END;
/

--Add a privilege to Access Control List
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
   acl          => 'apifuifi.xml',
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
   acl          => 'apifuifi.xml',
   host         => '*.fuifi.com');
  COMMIT;
END;
/
```

Para crear los componentes necesarios en nuestro esquema creado (en el ejemplo "HR"), lanzamos el script de inicializacion y la compilacion del paquete "imputador":
```
@init/database.sql
@src/imputador.pks
@src/imputador.pkb
```

Durante su ejecuci�n se pediran 3 par�metros a rellenar:
 * user: Tu usuario de la API fuifi
 * pass: Tu password de la API fuifi
 * domain: La organizaci�n de la API fuifi

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
  --Ultimos 30 dias
  set serveroutput on
  declare
    tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
  begin

    tDiasImputar.EXTEND(2);
    --dia 1
    tDiasImputar(1).DATEIM := TO_DATE('20/11/2019','DD/MM/YYYY');
    tDiasImputar(1).STARTTIME := TO_DATE('20/11/2019 08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).ENDTIME := TO_DATE('20/11/2019 21:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).TIMEEFECTIVE := TO_DATE('20/11/2019 12:00','DD/MM/YYYY HH24:MI');
    --dia 2
    tDiasImputar(2).DATEIM := TO_DATE('21/11/2019','DD/MM/YYYY');
    tDiasImputar(2).STARTTIME := TO_DATE('21/11/2019 08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(2).ENDTIME := TO_DATE('21/11/2019 15:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(2).TIMEEFECTIVE := TO_DATE('21/11/2019 07:00','DD/MM/YYYY HH24:MI');
    --dias N.....

    imputador.setImputationsWrapper(tDayImputations => tDiasImputar);
  end;
  /
  ```

  * Especificar un rango de fechas, y un conjunto de d�as modelo para los 5 dias laborales, imputandose en todo el periodo indicado, haciendo uso de la imputaci�n del d�a modelo de semana:  

  ``` sql
  --Ultimos 30 dias
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
