/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion) -> plsql-j-imputador
 */
SET DEFINE OFF
CREATE OR REPLACE PACKAGE BODY IMPUTADOR AS

  TYPE T_TOKEN IS RECORD(
    TOKENTYPE VARCHAR2(300),
    TOKEN VARCHAR2(32000)
  );

  TYPE HTTP_HEADER IS RECORD(
    HEADER VARCHAR2(300),
    VALUE VARCHAR2(32000)
  );

  TYPE T_HTTP_HEADER IS TABLE OF HTTP_HEADER;


  FUNCTION getConfiguration(config_ CONFIGURATION.CONFIGURATION%TYPE)
  RETURN CONFIGURATION.VALUE%TYPE IS
    value_ CONFIGURATION.VALUE%TYPE;
  BEGIN --getConfiguration
    SELECT VALUE
    INTO value_
    FROM CONFIGURATION
    WHERE CONFIGURATION = config_;
    RETURN value_;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END getConfiguration;


  FUNCTION postUrl(url VARCHAR2, thttpHeader T_HTTP_HEADER, content VARCHAR2, optionhttp VARCHAR2 := 'POST')
  RETURN CLOB IS
    req utl_http.req;
    res utl_http.resp;
    l_text CLOB;
  BEGIN

    utl_http.set_wallet('file:' || getConfiguration('WALLE'), getConfiguration('WALPS'));

    req := utl_http.begin_request(url, optionhttp,'HTTP/1.1');

    --utl_http.set_header(req, 'User-Agent', 'mozilla/4.0');
    IF thttpHeader IS NOT NULL AND thttpHeader.COUNT > 0 THEN
      FOR i IN thttpHeader.FIRST..thttpHeader.LAST LOOP
        IF thttpHeader.EXISTS(i) THEN
          utl_http.set_header(req, thttpHeader(i).HEADER, thttpHeader(i).VALUE);
          dbms_output.put_line('Cabecera-> ' || thttpHeader(i).HEADER || ': ' || thttpHeader(i).VALUE);
        END IF;
      END LOOP;
    END IF;

    IF optionhttp = 'POST' THEN
      --always content-length
      utl_http.set_header(req, 'Content-Length', length(content));

      utl_http.write_text(req, content);
    END IF;

    res := utl_http.get_response(req);

    if (res.status_code = UTL_HTTP.HTTP_OK) then

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

    else
      dbms_output.put_line('[ERROR]: Received non-OK response: '||res.status_code||' '||res.reason_phrase);
    end if;

    utl_http.end_response(res);

    RETURN l_text;
  END postUrl;



  FUNCTION getTokenAuthorization RETURN T_TOKEN IS
    user_ CONFIGURATION.VALUE%TYPE;
    pass_ CONFIGURATION.VALUE%TYPE;
    domain_ CONFIGURATION.VALUE%TYPE;
    urlBase_ CONFIGURATION.VALUE%TYPE;
    urlLogin_ CONFIGURATION.VALUE%TYPE;
    htmlResponse CLOB;
    jsonResponse JSON_OBJECT_T;
    tokenTypeJSON  JSON_OBJECT_T;
    tokenJSON  JSON_OBJECT_T;
    tToken T_TOKEN;
    thttpHeader T_HTTP_HEADER := T_HTTP_HEADER();
  BEGIN
    urlBase_ := getConfiguration('URLBA');
    urlLogin_ := getConfiguration('URLLO');
    user_ := getConfiguration('USER');
    pass_ := getConfiguration('PASS');
    domain_ := getConfiguration('DOMA');

    thttpHeader.EXTEND(1);
    thttpHeader(1).HEADER := 'Content-Type';
    thttpHeader(1).VALUE := 'application/json';

    htmlResponse := postUrl(urlBase_ || urlLogin_, thttpHeader,
                            '{"username":"'||user_||'","password":"'||pass_||'","domain_web":"'||domain_||'"}');
    IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN

      jsonResponse := JSON_OBJECT_T(htmlResponse);
      tToken.TOKENTYPE := jsonResponse.get_string('token_type');
      tToken.TOKEN := jsonResponse.get_string('access_token');
    END IF;

    RETURN tToken;

  END getTokenAuthorization;


  PROCEDURE getImputations(lastImputations INTEGER := 15) IS
    tToken T_TOKEN;
    urlBase_ CONFIGURATION.VALUE%TYPE;
    urlConsulta_ CONFIGURATION.VALUE%TYPE;
    htmlResponse CLOB;
    thttpHeader T_HTTP_HEADER := T_HTTP_HEADER();

  BEGIN --getImputations
    tToken := getTokenAuthorization();
    dbms_output.put_line('token: '||tToken.TOKENTYPE || ' ' ||tToken.TOKEN);

    urlBase_ := getConfiguration('URLBA');
    urlConsulta_ := getConfiguration('URLCO');

    thttpHeader.EXTEND(3);
    thttpHeader(1).HEADER := 'Content-Type';
    thttpHeader(1).VALUE := 'application/json';
    thttpHeader(2).HEADER := 'User-Agent';
    thttpHeader(2).VALUE := 'Mozilla/4.0';
    thttpHeader(3).HEADER := 'Authorization';
    thttpHeader(3).VALUE := tToken.TOKENTYPE || ' ' || tToken.TOKEN;
    urlConsulta_ := REPLACE(urlConsulta_,'{0}',lastImputations);


    htmlResponse := postUrl(urlBase_ || urlConsulta_, thttpHeader,
                            '',
                            optionhttp => 'GET');

     delete borrame;
     insert into borrame(COL) values(htmlResponse);
     COMMIT;


  END getImputations;

END IMPUTADOR;
/
SHOW ERRORS
