/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-imputador)
 * License: GNU General Public License v3.0
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


  --PRIVATE
  ---------------------------------------------------------------------------------------------

  /**
   * Recover configuration value
   * @param config_ Configuration code
   * @return Configuration value
   */
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

  /**
   * Attack api fuifi.
   * @param url Attack url
   * @param thttpHeader Type with all headers
   * @param content Body (only post)
   * @param optionhttp API Method... default is POST
   * @return Api's return
   */
  FUNCTION attackUrl(url VARCHAR2, thttpHeader T_HTTP_HEADER, content VARCHAR2, optionhttp VARCHAR2 := 'POST')
  RETURN CLOB IS
    req utl_http.req;
    res utl_http.resp;
    l_text CLOB;

    jsonResponse JSON_OBJECT_T;
  BEGIN
--dbms_output.put_line('URL-> ' || url);

    utl_http.set_wallet('file:' || getConfiguration('WALLE'), getConfiguration('WALPS'));

    req := utl_http.begin_request(url, optionhttp,'HTTP/1.1');

    IF thttpHeader IS NOT NULL AND thttpHeader.COUNT > 0 THEN
      FOR i IN thttpHeader.FIRST..thttpHeader.LAST LOOP
        IF thttpHeader.EXISTS(i) THEN
          utl_http.set_header(req, thttpHeader(i).HEADER, thttpHeader(i).VALUE);
--dbms_output.put_line('Cabecera-> ' || thttpHeader(i).HEADER || ': ' || thttpHeader(i).VALUE);
        END IF;
      END LOOP;
    END IF;


--dbms_output.put_line('content-> ' ||content);
    IF optionhttp = 'POST' THEN
      --always content-length
      utl_http.set_header(req, 'Content-Length', length(content));

      utl_http.write_text(req, content);
    END IF;

    res := utl_http.get_response(req);

--dbms_output.put_line('Respuesta: ' || res.status_code);
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
      --si tego un json de respuesta, lo voy a cargar... se supone que desde el invocador tratar el error de respuesta
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

    end if;

    utl_http.end_response(res);

    RETURN l_text;
  END attackUrl;

  /**
   * Visit fuifi url web, for win points.... It is new for I can do imputation
   * @param tToken Token de autenticacion
   */
  PROCEDURE visitPoints(tToken T_TOKEN) IS

    urlBase_ CONFIGURATION.VALUE%TYPE;
    urlPoints_ CONFIGURATION.VALUE%TYPE;
    htmlResponse CLOB;
    thttpHeader T_HTTP_HEADER := T_HTTP_HEADER();
    --thttpHeader2 T_HTTP_HEADER := T_HTTP_HEADER();
  BEGIN --visitPoints

    urlBase_ := getConfiguration('URLBA');
    urlPoints_ := getConfiguration('URLPO');

    thttpHeader.EXTEND(2);
    thttpHeader(1).HEADER := 'User-Agent';
    thttpHeader(1).VALUE := 'Mozilla/4.0';
    thttpHeader(2).HEADER := 'Authorization';
    thttpHeader(2).VALUE := tToken.TOKENTYPE || ' ' || tToken.TOKEN;

    --https://web.fuifi.com/#/tabs/inicio/home
    --Check api url for firt Login today
    htmlResponse := attackUrl(urlBase_ || urlPoints_, thttpHeader,
                            '',
                            optionhttp => 'GET');
    IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN
      --dbms_output.put_line(SUBSTR(htmlResponse,1,400));
      NULL;

      --ADD (i think it is not necessary): visit puntos_hoy_es.json web url
      --for the moment.... it is not necessary
      -- htmlResponse := attackUrl('https://web.fuifi.com/assets/lottie/puntos_hoy_es.json', thttpHeader,
      --                         '',
      --                         optionhttp => 'GET');
      --
      -- IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN
      --   dbms_output.put_line(SUBSTR(htmlResponse,1,400));
      --   NULL;
      --
      -- ELSE
      --   dbms_output.put_line('[ERROR]: Web fuifi puntos_hoy_es KO');
      -- END IF;

    ELSE
      dbms_output.put_line('[ERROR]: Web fuifi firstLoginToday KO');
    END IF;

  END visitPoints;

  /**
   * Get a token for api comunications
   * @return Token type
   */
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

    htmlResponse := attackUrl(urlBase_ || urlLogin_, thttpHeader,
                            '{"username":"'||user_||'","password":"'||pass_||'","domain_web":"'||domain_||'"}');
    IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN

      jsonResponse := JSON_OBJECT_T(htmlResponse);
      tToken.TOKENTYPE := jsonResponse.get_string('token_type');
      tToken.TOKEN := jsonResponse.get_string('access_token');
--dbms_output.put_line('getTokenAuthorization -> token: '||tToken.TOKENTYPE || ' ' ||tToken.TOKEN);

      --now... it is necesary to visti web fuifi for to win 10 points
      visitPoints(tToken);

    END IF;

    RETURN tToken;

  END getTokenAuthorization;

  /**
   * Change time parameter add/minus random minutes value: 1-5 minutes
   * @param time Datetime in
   * @return Changed datetime
   */
  FUNCTION setRandomTime(time DATE)
  RETURN DATE IS
    numRandomTime INTEGER;
    newTime DATE;
  BEGIN --setRandomTime
    numRandomTime := (1+ABS(MOD(dbms_random.random,5)));
    IF (1+ABS(MOD(dbms_random.random,2))) = 1 THEN
      newTime := time + (1/1440*numRandomTime);
    ELSE
      newTime := time - (1/1440*numRandomTime);
    END IF;
    RETURN newTime;
  END setRandomTime;

  /**
   * Change time parameter minus random minutes value: 1-15 minutes
   * @param time Datetime in
   * @return Changed datetime
   */
  FUNCTION setRandomTimeEfec(time DATE)
  RETURN DATE IS
    numRandomTime INTEGER;
    newTime DATE;
  BEGIN --setRandomTimeEfec
    numRandomTime := (1+ABS(MOD(dbms_random.random,15)));
    newTime := time - (1/1440*numRandomTime);
    RETURN newTime;
  END setRandomTimeEfec;

  /**
   * Check if time efec is correct after to apply random start/end time
   * @param tDayimputationReview info imputation
   * @return Info imputation with efective time check
   */
  PROCEDURE checkTimeEfecRamdonStart(tDayimputationReview IN OUT NOCOPY T_DAYIMPUTATION) IS
    minutesTot INTEGER;
    hours INTEGER;
    minutes INTEGER;
    timeEfecReal DATE;
  BEGIN --checkTimeEfecRamdonStart
    minutesTot := (tDayimputationReview.ENDTIME - tDayimputationReview.STARTTIME)  * 24 * 60;
    hours := TRUNC(minutesTot / 60);
    minutes := ROUND(minutesTot - (TRUNC(minutesTot / 60) * 60));
    timeEfecReal := TO_DATE(TO_CHAR(tDayimputationReview.TIMEEFECTIVE,'DD/MM/YYYY') || ' ' || hours ||':'||minutes, 'DD/MM/YYYY HH24:MI');
    IF tDayimputationReview.TIMEEFECTIVE > timeEfecReal THEN
      tDayimputationReview.TIMEEFECTIVE := timeEfecReal;
    END IF;
  END checkTimeEfecRamdonStart;


  /**
   * Set one day in imputations
   * @param tDayimputation Day's data
   * @param tStatusImpusResult Fill result
   * @param randomTime Add random in start time, end time -> 5 minutes before or after
   * @param randomEfective Add random in efective time -> 5 minutes before
   */
  PROCEDURE setDayImputation(tDayimputation T_DAYIMPUTATION,
                             tStatusImpusResult IN OUT NOCOPY T_STATUSIMPUS,
                             randomTime BOOLEAN := FALSE,
                             randomEfective BOOLEAN := FALSE)  IS
    tToken T_TOKEN;
    urlBase_ CONFIGURATION.VALUE%TYPE;
    urlImputa_ CONFIGURATION.VALUE%TYPE;
    htmlResponse CLOB;
    thttpHeader T_HTTP_HEADER := T_HTTP_HEADER();

    jsonResponse JSON_OBJECT_T;

    tStatusimpu T_STATUSIMPU;
    indexNewResult INTEGER;

    tDayimputationReview T_DAYIMPUTATION;
  BEGIN  --setDayImputation

    tToken := getTokenAuthorization();
    --dbms_output.put_line('token: '||tToken.TOKENTYPE || ' ' ||tToken.TOKEN);

    urlBase_ := getConfiguration('URLBA');
    urlImputa_ := getConfiguration('URLIM');

    thttpHeader.EXTEND(3);
    thttpHeader(1).HEADER := 'Content-Type';
    thttpHeader(1).VALUE := 'application/json';
    thttpHeader(2).HEADER := 'User-Agent';
    thttpHeader(2).VALUE := 'Mozilla/4.0';
    thttpHeader(3).HEADER := 'Authorization';
    thttpHeader(3).VALUE := tToken.TOKENTYPE || ' ' || tToken.TOKEN;



    --Check random review
    tDayimputationReview := tDayimputation;
    IF randomTime THEN
      --random start time
      tDayimputationReview.STARTTIME := setRandomTime(tDayimputation.STARTTIME);

      --random end time
      tDayimputationReview.ENDTIME := setRandomTime(tDayimputation.ENDTIME);

      --apply random start/end time in timeefective -> no more time
      checkTimeEfecRamdonStart(tDayimputationReview);

      --Check random minus time effective
      IF randomEfective THEN
        tDayimputationReview.TIMEEFECTIVE := setRandomTimeEfec(tDayimputationReview.TIMEEFECTIVE);
      END IF;
    END IF;

    -- dbms_output.put_line('Día ' || TO_CHAR(tDayimputationReview.DATEIM,'DD/MM/YYYY') || ' -> ' ||
    --           'Inicio' || ': ' || TO_CHAR(tDayimputationReview.STARTTIME,'HH24:MI') || ' - ' ||
    --           'Fin' || ': '|| TO_CHAR(tDayimputationReview.ENDTIME,'HH24:MI') || ' - ' ||
    --           'Efect time' || ': '|| TO_CHAR(tDayimputationReview.TIMEEFECTIVE,'HH24:MI'));


    htmlResponse := attackUrl(urlBase_ || urlImputa_, thttpHeader,
                            '{"date":"'||TO_CHAR(tDayimputationReview.DATEIM,'YYYY-MM-DD')||
                            '","effective_time":"'||TO_CHAR(tDayimputationReview.TIMEEFECTIVE,'HH24:MI')||
                            '","time_from":"'||TO_CHAR(tDayimputationReview.STARTTIME,'HH24:MI')||
                            '","time_to":"'||TO_CHAR(tDayimputationReview.ENDTIME,'HH24:MI')||'"}');
    IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN

      jsonResponse := JSON_OBJECT_T(htmlResponse);
      tStatusimpu.STATUS := jsonResponse.get_string('status');
      tStatusimpu.STATUSCODE := jsonResponse.get_string('status_code');
      tStatusimpu.MESSAGE := jsonResponse.get_string('message');
      tStatusimpu.DATEIM := tDayimputationReview.DATEIM;

      indexNewResult := NVL(tStatusImpusResult.LAST, 0) + 1;
      tStatusImpusResult(indexNewResult) := tStatusimpu;
      -- dbms_output.put_line('Día ' || TO_CHAR(tDayimputationReview.DATEIM,'DD/MM/YYYY') || ' -> ' ||
      --           tStatusimpu.STATUS || ' - ' ||
      --           tStatusimpu.STATUSCODE || ' - '||
      --           tStatusimpu.MESSAGE);
    END IF;

-- delete borrame;
-- insert into borrame(COL) values(htmlResponse);
-- COMMIT;

  END setDayImputation;


  --PUBLIC
  ---------------------------------------------------------------------------------------------


  /**
   * Get last N imputations
   * @param lastImputations
   * @return Type all get imputations
   */
  FUNCTION getImputations(lastImputations INTEGER := 15)
  RETURN T_LISTDATES IS
    tToken T_TOKEN;
    urlBase_ CONFIGURATION.VALUE%TYPE;
    urlConsulta_ CONFIGURATION.VALUE%TYPE;
    htmlResponse CLOB;
    thttpHeader T_HTTP_HEADER := T_HTTP_HEADER();

    jsonResponse JSON_OBJECT_T;
    dataJSON  JSON_OBJECT_T;
    arrayDataJSON JSON_ARRAY_T;
    dateJSON JSON_OBJECT_T;

    tListDates T_LISTDATE;

    fechaCad VARCHAR2(50);

    indexResult INTEGER := 1;
    tListDatesResult T_LISTDATES;
    countResult INTEGER := 0;

  BEGIN --getImputations
    tToken := getTokenAuthorization();
    --dbms_output.put_line('token: '||tToken.TOKENTYPE || ' ' ||tToken.TOKEN);

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


    htmlResponse := attackUrl(urlBase_ || urlConsulta_, thttpHeader,
                            '',
                            optionhttp => 'GET');

    IF NVL(dbms_lob.getlength(htmlResponse), 0) > 0 THEN

      --dbms_output.put_line(SUBSTR('getImputations -> htmlResponse: '||htmlResponse,1,500));

      jsonResponse := JSON_OBJECT_T(htmlResponse);
      arrayDataJSON := jsonResponse.get_array('data');
      <<dataLoop>>
      FOR i IN 0 .. arrayDataJSON.get_size - 1 LOOP
        IF arrayDataJSON.get(i).is_object THEN
          countResult := countResult + 1;
          --Always minimun result is 15... if i need less -> manually cut
          IF countResult <= lastImputations THEN
            --DBMS_OUTPUT.put_line(arrayDataJSON.get(i).stringify);
            dateJSON := TREAT(arrayDataJSON.get(i) AS JSON_OBJECT_T);
            fechaCad := dateJSON.get_string('date');
            tListDates.DATEIM := TO_DATE(fechaCad,'YYYY-MM-DD');
            tListDates.STARTTIME := TO_DATE(fechaCad || ' ' || dateJSON.get_string('date_start'),'YYYY-MM-DD HH24:MI:SS');
            tListDates.ENDTIME := TO_DATE(fechaCad || ' ' || dateJSON.get_string('date_end'),'YYYY-MM-DD HH24:MI:SS');
            tListDates.TIMEEFECTIVE := TO_DATE(fechaCad || ' ' || dateJSON.get_string('effective_time'),'YYYY-MM-DD HH24:MI:SS');

            --las horas las devuelve en hora estandar sin aplicar el offset del time zone...
            --a si que se lo aplicamos nosotros al de españa
            tListDates.STARTTIME := from_tz(CAST(tListDates.STARTTIME as TIMESTAMP), 'GMT') at time zone 'Europe/Madrid';
            tListDates.ENDTIME := from_tz(CAST(tListDates.ENDTIME as TIMESTAMP), 'GMT') at time zone 'Europe/Madrid';

            tListDatesResult(indexResult) := tListDates;
            indexResult := indexResult + 1;
            -- dbms_output.put_line(
            --           TO_CHAR(tListDates.DATEIM, 'DD/MM/YYYY') || '  ' ||
            --           TO_CHAR(tListDates.STARTTIME, 'HH24:MI') || '    '||
            --           TO_CHAR(tListDates.ENDTIME, 'HH24:MI') || '    '||
            --           TO_CHAR(tListDates.TIMEEFECTIVE, 'HH24:MI'));
          END IF;
        END IF;
      END LOOP dataLoop;

    END IF;

 -- delete borrame;
 -- insert into borrame(COL) values(htmlResponse);
 -- COMMIT;

    RETURN tListDatesResult;
  END getImputations;


  /**
   * Display on screen last N imputations
   * @param lastImputations
   */
  PROCEDURE getImputationsWrapper(lastImputations INTEGER := 15) IS
    tListDatesResult T_LISTDATES;
  BEGIN --getImputationsWrapper
    tListDatesResult := getImputations(lastImputations);
    dbms_output.put_line('Ultimas ' || lastImputations || ' imputaciones');
    dbms_output.put_line('----------------------------------------------');
    dbms_output.put_line('Fecha       Inicio   Fin      Tiempo Efec.');
    dbms_output.put_line('----------  -------  -------  ------------');
    <<loopResulDates>>
    FOR i IN NVL(tListDatesResult.FIRST, 0)..NVL(tListDatesResult.LAST, -1) LOOP
      dbms_output.put_line(
                TO_CHAR(tListDatesResult(i).DATEIM, 'DD/MM/YYYY') || '  ' ||
                TO_CHAR(tListDatesResult(i).STARTTIME, 'HH24:MI') || '    '||
                TO_CHAR(tListDatesResult(i).ENDTIME, 'HH24:MI') || '    '||
                TO_CHAR(tListDatesResult(i).TIMEEFECTIVE, 'HH24:MI'));
    END LOOP loopResulDates;
  END getImputationsWrapper;




  /**
   * Set imputations.
   * @param tDayImputations Optional, if you imputation is for each day
   * @param startDate Optional, if you imputation is for model day. Start date
   * @param endDate Optional, if you imputation is for model day. End date
   * @param tModelDays Optional, if you imputation is for model day. 5 model days -> mondays-fridays
   * @param randomTime Add random in start time, end time -> 5 minutes before or after
   * @param randomEfective Add random in efective time -> 5 minutes before
   * @return Type all set imputations done
   */
  FUNCTION setImputations(
                      tDayImputations IMPUTADOR.T_DAYIMPUTATIONS := NULL,
                      startDate DATE := NULL,
                      endDate DATE := NULL,
                      tModelDays IMPUTADOR.T_MODELDAYS := NULL,
                      randomTime BOOLEAN := FALSE,
                      randomEfective BOOLEAN := FALSE)
  RETURN T_STATUSIMPUS IS
    dateActually DATE;
    indexDayModel INTEGER;
    tDayimputation T_DAYIMPUTATION;

    indexResult INTEGER := 1;
    tStatusImpusResult T_STATUSIMPUS;
  BEGIN --setImputations
    --check parameter
    IF (tDayImputations IS NOT NULL AND tDayImputations.COUNT > 0)
      OR
       (startDate IS NOT NULL AND endDate IS NOT NULL AND tModelDays IS NOT NULL AND tModelDays.COUNT = 5) THEN

      IF tDayImputations IS NOT NULL AND tDayImputations.COUNT > 0 THEN
        <<loopDays>>
        FOR i IN tDayImputations.FIRST..tDayImputations.LAST LOOP
          IF tDayImputations.EXISTS(i) THEN
            setDayImputation(tDayImputations(i),
                             --in/out -> fill result
                             tStatusImpusResult,
                             randomTime, randomEfective);
          END IF;
        END LOOP loopDays;

      ELSIF startDate IS NOT NULL AND endDate IS NOT NULL AND tModelDays IS NOT NULL AND tModelDays.COUNT = 5 THEN
        dateActually := startDate;
        <<loopRange>>
        WHILE (dateActually <= endDate) LOOP
          CASE
            WHEN TO_CHAR(dateActually,'DY') IN ('MON','LUN') THEN indexDayModel := 1;
            WHEN TO_CHAR(dateActually,'DY') IN ('TUE','MAR') THEN indexDayModel := 2;
            WHEN TO_CHAR(dateActually,'DY') IN ('WED','MIÉ') THEN indexDayModel := 3;
            WHEN TO_CHAR(dateActually,'DY') IN ('THU','JUE') THEN indexDayModel := 4;
            WHEN TO_CHAR(dateActually,'DY') IN ('FRI','VIE') THEN indexDayModel := 5;
            ELSE indexDayModel := null;
          END CASE;
          IF indexDayModel IS NOT NULL AND tModelDays.EXISTS(indexDayModel) THEN
            tDayimputation.DATEIM := dateActually;
            tDayimputation.STARTTIME := tModelDays(indexDayModel).STARTTIME;
            tDayimputation.ENDTIME := tModelDays(indexDayModel).ENDTIME;
            tDayimputation.TIMEEFECTIVE := tModelDays(indexDayModel).TIMEEFECTIVE;
            setDayImputation(tDayimputation,
                             --in/out -> fill result
                             tStatusImpusResult,
                             randomTime, randomEfective);
          END IF;
          dateActually := dateActually + 1;
        END LOOP loopRange;
      END IF;

    ELSE
      dbms_output.put_line('[ERROR]: ' || 'parámetros incorrectos');
    END IF;

    RETURN tStatusImpusResult;

  END setImputations;

  /**
   * Set imputations.
   * Display on screen "Dia -> operation result"
   * @param tDayImputations Optional, if you imputation is for each day
   * @param startDate Optional, if you imputation is for model day. Start date
   * @param endDate Optional, if you imputation is for model day. End date
   * @param tModelDays Optional, if you imputation is for model day. 5 model days -> mondays-fridays
   * @param randomTime Add random in start time, end time -> 5 minutes before or after
   * @param randomEfective Add random in efective time -> 5 minutes before
   */
  PROCEDURE setImputationsWrapper(
                      tDayImputations IMPUTADOR.T_DAYIMPUTATIONS := NULL,
                      startDate DATE := NULL,
                      endDate DATE := NULL,
                      tModelDays IMPUTADOR.T_MODELDAYS := NULL,
                      randomTime BOOLEAN := FALSE,
                      randomEfective BOOLEAN := FALSE) IS
    tStatusImpusResult T_STATUSIMPUS;
  BEGIN  --setImputationsWrapper
    tStatusImpusResult := setImputations(
                          tDayImputations, startDate, endDate, tModelDays, randomTime, randomEfective);
    <<loopResulSet>>
    FOR i IN NVL(tStatusImpusResult.FIRST, 0)..NVL(tStatusImpusResult.LAST, -1) LOOP
      dbms_output.put_line('Dia ' || TO_CHAR(tStatusImpusResult(i).DATEIM,'DD/MM/YYYY') || ' -> ' ||
                tStatusImpusResult(i).STATUS || ' - ' ||
                tStatusImpusResult(i).STATUSCODE || ' - '||
                tStatusImpusResult(i).MESSAGE);
    END LOOP loopResulSet;
  END setImputationsWrapper;


END IMPUTADOR;
/
SHOW ERRORS
