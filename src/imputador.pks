/**
 * imputation hours recorder
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-imputador)
 * License: GNU General Public License v3.0
 */
CREATE OR REPLACE PACKAGE IMPUTADOR AS

  --Type: wrapper getImputations
  TYPE T_LISTDATE IS RECORD(
    DATEIM DATE,
    STARTTIME DATE,
    ENDTIME DATE,
    TIMEEFECTIVE DATE
  );

  TYPE T_LISTDATES IS TABLE OF T_LISTDATE INDEX BY BINARY_INTEGER;


  --Type: wrapper setImputations
  TYPE T_STATUSIMPU IS RECORD(
    DATEIM DATE,
    STATUS VARCHAR2(300),
    STATUSCODE VARCHAR2(300),
    MESSAGE VARCHAR2(4000)
  );

  TYPE T_STATUSIMPUS IS TABLE OF T_STATUSIMPU INDEX BY BINARY_INTEGER;

  --Type: param tDayImputations in setImputations
  TYPE T_DAYIMPUTATION IS RECORD(
    DATEIM DATE,
    STARTTIME DATE,
    ENDTIME DATE,
    TIMEEFECTIVE DATE
  );

  TYPE T_DAYIMPUTATIONS IS TABLE OF T_DAYIMPUTATION;

  --Type: param tModelDays in setImputations
  TYPE T_MODELDAY IS RECORD(
    STARTTIME DATE,
    ENDTIME DATE,
    TIMEEFECTIVE DATE
  );

  TYPE T_MODELDAYS IS TABLE OF T_MODELDAY;


  /**
   * Get last N imputations
   * @param lastImputations
   * @return Type all get imputations
   */
  FUNCTION getImputations(lastImputations INTEGER := 15)
  RETURN T_LISTDATES;

  /**
   * Display on screen last N imputations
   * @param lastImputations
   */
  PROCEDURE getImputationsWrapper(lastImputations INTEGER := 15);

  /**
   * Set imputations.
   * @param tDayImputations Optional, if you imputation is for each day
   * @param startDate Optional, if you imputation is for model day. Start date
   * @param endDate Optional, if you imputation is for model day. End date
   * @param tModelDays Optional, if you imputation is for model day. 5 model days -> mondays-fridays
   * @return Type all set imputations done
   */
  FUNCTION setImputations(
                      tDayImputations IMPUTADOR.T_DAYIMPUTATIONS := NULL,
                      startDate DATE := NULL,
                      endDate DATE := NULL,
                      tModelDays IMPUTADOR.T_MODELDAYS := NULL)
  RETURN T_STATUSIMPUS;


  /**
   * Set imputations.
   * Display on screen "Dia -> operation result"
   * @param tDayImputations Optional, if you imputation is for each day
   * @param startDate Optional, if you imputation is for model day. Start date
   * @param endDate Optional, if you imputation is for model day. End date
   * @param tModelDays Optional, if you imputation is for model day. 5 model days -> mondays-fridays
   */
  PROCEDURE setImputationsWrapper(
                      tDayImputations IMPUTADOR.T_DAYIMPUTATIONS := NULL,
                      startDate DATE := NULL,
                      endDate DATE := NULL,
                      tModelDays IMPUTADOR.T_MODELDAYS := NULL);


END IMPUTADOR;
/
SHOW ERRORS
