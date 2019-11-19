/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion) -> plsql-j-imputador
 */
CREATE OR REPLACE PACKAGE IMPUTADOR AS


/*
@TODO: Prerequisitos:
GRANT EXECUTE ON SYS.UTL_HTTP TO HR;

https://oracle-base.com/articles/misc/utl_http-and-ssl

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
  -Docker 18c
    mkdir -p /opt/oracle/admin/ORCLCDB/wallet
    orapki wallet create -wallet /opt/oracle/admin/ORCLCDB/wallet -pwd WalletPasswd123 -auto_login

  -En teoria basta con el de la entidad padre certificadora de toda la ruta:
    orapki wallet add -wallet /opt/oracle/admin/ORCLCDB/wallet -cert /var/jortri/tnsnames/USERTrustRSACertificationAuthority.crt -trusted_cert -pwd WalletPasswd123

  -Si queremos ver lo cargado:
    orapki wallet display -wallet  /opt/oracle/admin/ORCLCDB/wallet


 */



  /**
   * Return number of days between two dates
   * @param lastImputations
   * @return
   */
  PROCEDURE getImputations(lastImputations INTEGER := 15);


END IMPUTADOR;
/
SHOW ERRORS
