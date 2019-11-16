/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion) -> plsql-j-imputador
 */
CREATE OR REPLACE PACKAGE BODY IMPUTADOR AS

  FUNCTION postUrl(url VARCHAR2, content VARCHAR2)
  RETURN CLOB IS
    req utl_http.req;
    res utl_http.resp;
    l_text CLOB;
  BEGIN

    req := utl_http.begin_request(url, 'POST',' HTTP/1.1');

    UTL_HTTP.set_wallet('file:/opt/oracle/admin/ORCLCDB/wallet/', 'WalletPasswd123');

    utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(req, 'content-type', 'application/json');
    utl_http.set_header(req, 'Content-Length', length(content));
    utl_http.set_header(req, 'username', 'jgalvez');
    utl_http.set_header(req, 'password', 'Cuenca2020!');
    utl_http.set_header(req, 'domain_web', 'alfatecsistemas.es');

    utl_http.write_text(req, content);

    res := utl_http.get_response(req);
    Dbms_Lob.CreateTemporary( l_text, TRUE, Dbms_Lob.SESSION );
    -- loop through the data coming back
    <<loopData>>
    DECLARE
      value VARCHAR2(32767);
    BEGIN
      LOOP
        UTL_HTTP.READ_TEXT(res, value, 32000);
        Dbms_Lob.Append(l_text, value);
      END LOOP;
    EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
        NULL;
    END loopData;
    utl_http.end_response(res);

    RETURN l_text;
  END postUrl;


  PROCEDURE getImputations(minDate DATE, maxDate DATE) IS
    htmlResponse CLOB;
  BEGIN --getImputations
    htmlResponse := postUrl('https://api.fuifi.com/api/v1/login', '');
    delete borrame;
    insert into borrame(COL) values(htmlResponse);
    COMMIT;


  END getImputations;

END IMPUTADOR;
/
SHOW ERRORS
