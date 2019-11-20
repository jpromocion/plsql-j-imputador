/**
 * Utplsql unit test for imputador
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-utilxml)
 * License: GNU General Public License v3.0
 */
SET DEFINE OFF
CREATE OR REPLACE PACKAGE BODY UT_UTILXML AS


  /******************************************************************
  ************* AUXILIARY *******************************************
  *******************************************************************/

  PROCEDURE setNlsDate IS
  BEGIN
    execute immediate(q'(ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY')');
  END setNlsDate;



  /******************************************************************
  ************* TEST PROCEDURE **************************************
  *******************************************************************/

  PROCEDURE getImputations_01 IS
    tListDatesResult Imputador.T_LISTDATES;
  BEGIN
    tListDatesResult := Imputador.getImputations();

    ut.expect( tListDatesResult.COUNT ).to_equal(15);

  END getImputations_01;

  PROCEDURE getImputations_02 IS
    tListDatesResult Imputador.T_LISTDATES;
  BEGIN
    tListDatesResult := Imputador.getImputations(0);

    ut.expect( NVL(tListDatesResult.COUNT,0) ).to_equal(0);

  END getImputations_02;

  PROCEDURE getImputations_03 IS
    tListDatesResult Imputador.T_LISTDATES;
  BEGIN
    tListDatesResult := Imputador.getImputations(1);

    ut.expect( NVL(tListDatesResult.COUNT,0) ).to_equal(1);

  END getImputations_03;

  PROCEDURE getImputations_04 IS
    tListDatesResult Imputador.T_LISTDATES;
  BEGIN
    tListDatesResult := Imputador.getImputations(100);

    ut.expect( NVL(tListDatesResult.COUNT,0) ).to_equal(100);

  END getImputations_04;

  PROCEDURE setImputations_01 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
  BEGIN
    tStatusImpusResult := Imputador.setImputations();

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(0);
  END setImputations_01;

  PROCEDURE setImputations_02 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
  BEGIN
    tStatusImpusResult := Imputador.setImputations(startDate => TO_DATE('20/11/2019','DD/MM/YYYY'),
                                                   endDate => TO_DATE('21/11/2019','DD/MM/YYYY'));

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(0);
  END setImputations_02;

  PROCEDURE setImputations_03 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
    tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
  BEGIN
    tStatusImpusResult := Imputador.setImputations(tDayImputations => tDiasImputar);

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(0);
  END setImputations_03;

  PROCEDURE setImputations_04 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
    tDiasModelo Imputador.T_MODELDAYS  := Imputador.T_MODELDAYS();
  BEGIN
    tStatusImpusResult := Imputador.setImputations(startDate => TO_DATE('20/11/2019','DD/MM/YYYY'),
                                    endDate => TO_DATE('21/11/2019','DD/MM/YYYY'),
                                    tModelDays => tDiasModelo);

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(0);
  END setImputations_04;

  PROCEDURE setImputations_05 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
    tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
  BEGIN
    tDiasImputar.EXTEND(1);
    --dia 1
    tDiasImputar(1).DATEIM := TRUNC(SYSDATE,'DD/MM/YYYY');
    tDiasImputar(1).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00','DD/MM/YYYY HH24:MI');

    tStatusImpusResult := Imputador.setImputations(tDayImputations => tDiasImputar);

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(1);
  END setImputations_05;

  PROCEDURE setImputations_06 IS
    tStatusImpusResult Imputador.T_STATUSIMPUS;
    tDiasImputar Imputador.T_DAYIMPUTATIONS  := Imputador.T_DAYIMPUTATIONS();
  BEGIN
    tDiasImputar.EXTEND(1);
    --dia 1
    tDiasImputar(1).DATEIM := TRUNC(SYSDATE,'DD/MM/YYYY');
    tDiasImputar(1).STARTTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '08:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).ENDTIME := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '15:00','DD/MM/YYYY HH24:MI');
    tDiasImputar(1).TIMEEFECTIVE := TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YYYY') || ' ' || '07:00','DD/MM/YYYY HH24:MI');

    tStatusImpusResult := Imputador.setImputations(tDayImputations => tDiasImputar);

    ut.expect( NVL(tStatusImpusResult.COUNT,0) ).to_equal(0);
  END setImputations_06;

END UT_UTILXML;
/
SHOW ERRORS
