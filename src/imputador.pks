/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion) -> plsql-j-imputador
 */
CREATE OR REPLACE PACKAGE IMPUTADOR AS


/*
@TODO: Prerequisitos:
GRANT EXECUTE ON SYS.UTL_HTTP TO HR;

https://oracle-base.com/articles/misc/utl_http-and-ssl_

Y ACL:




BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
   acl          => 'apifuifi.xml',
   description  => 'Permissions to access https://api.fuifi.com',
   principal    => 'HR',
   is_grant     => TRUE,
   privilege    => 'connect');
  COMMIT;
END;


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



--Assign a network host to Access Control List
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
   acl          => 'apifuifi.xml',
   host         => '*.fuifi.com');
  COMMIT;
END;


Y certificado en servidor:
  -Nueva carpeta C:\oraclexe\app\oracle\admin\XE\wallet (/u01/app/oracle/admin/DB11G/wallet)
    docker exec -it oracledb bash -c "mkdir -p /u01/app/oracle/admin/ORCL/wallet"

  -Creamos wallet:
    orapki wallet create -wallet C:\oraclexe\app\oracle\admin\XE\wallet -pwd WalletPasswd123 -auto_login
    NOTA: lo lleva la instalacion de jdeveloper 11 (C:\Oracle\Middleware\oracle_common\bin)

    docker exec -it oracledb bash -c "su - oracle; /u01/app/oracle/product/12.2.0/dbhome_1/jlib/oraclepki.jar wallet create -wallet /u01/app/oracle/admin/ORCL/wallet -pwd WalletPasswd123 -auto_login"

  -VAgrant18c:
    mkdir -p /opt/oracle/admin/ORCLCDB/wallet
    Copiamos en /opt/oracle/admin/ORCLCDB/wallet los que creamos


docker exec -it oracledb bash -c "ls -l /u01/app/oracle/product/12.2.0/dbhome_1/jlib/"

  -Bajar certificado de api.fuifi.com ->
  -MEter certificado en wallet:
    C:\Oracle\Middleware\oracle_common\bin\orapki wallet add -wallet C:\oraclexe\app\oracle\admin\XE\wallet -trusted_cert -cert "C:\Users\jgalvez\Desktop\api.fuifi.cer" -pwd WalletPasswd123

    docker exec -it oracledb bash -c "orapki wallet add -wallet /u01/app/oracle/admin/ORCL/wallet -trusted_cert -cert "C:\Users\jgalvez\Desktop\api.fuifi.cer" -pwd WalletPasswd123"

 */



  /**
   * Return number of days between two dates
   * @param minDate Minimun date
   * @param maxDate Maximun date
   * @return
   */
  PROCEDURE getImputations(minDate DATE, maxDate DATE);


END IMPUTADOR;
/
SHOW ERRORS
