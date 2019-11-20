/**
 * Utplsql unit test for imputador
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-imputador)
 * License: GNU General Public License v3.0
 */
CREATE OR REPLACE PACKAGE UT_UTILXML AS

  --%suite(Test imputador)
  --%suitepath(test.plsql.j.imputador)

  --%beforeall
  PROCEDURE setNlsDate;

  --%test(getImputations - 01 -> Check without parameter)
  PROCEDURE getImputations_01;

  --%test(getImputations - 02 -> Check with parameter 0)
  PROCEDURE getImputations_02;

  --%test(getImputations - 03 -> Check with parameter 1)
  PROCEDURE getImputations_03;

  --%test(getImputations - 04 -> Check with parameter 100)
  PROCEDURE getImputations_04;

  --%test(setImputations - 01 -> Parameter fail)
  PROCEDURE setImputations_01;

  --%test(setImputations - 02 -> Parameter fail)
  PROCEDURE setImputations_02;

  --%test(setImputations - 03 -> without days)
  PROCEDURE setImputations_03;

  --%test(setImputations - 04 -> without model days)
  PROCEDURE setImputations_04;

  --%test(setImputations - 05 -> imput day)
  PROCEDURE setImputations_05;

  --%test(setImputations - 06 -> imput same day -> impossible)
  PROCEDURE setImputations_06;

END UT_UTILXML;
/
SHOW ERRORS
