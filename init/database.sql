SET DEFINE ON

DROP TABLE CONFIGURATION;

CREATE TABLE CONFIGURATION(
  configuration varchar2(5) CONSTRAINT CONFIGURATION_PK PRIMARY KEY,
  value varchar2(500) NOT NULL
);

COMMENT ON TABLE CONFIGURATION IS 'configuration application';

insert into CONFIGURATION(configuration, value) values('URLBA','https://api.fuifi.com/');
insert into CONFIGURATION(configuration, value) values('URLLO','api/v1/login');
insert into CONFIGURATION(configuration, value) values('URLCO','api/v1/workdayrecord/getLastRecords?limit={0}&page=1');
insert into CONFIGURATION(configuration, value) values('URLIM','api/v1/workdayrecord/store/lazy');
insert into CONFIGURATION(configuration, value) values('USER','&&user');
insert into CONFIGURATION(configuration, value) values('PASS','&&pass');
insert into CONFIGURATION(configuration, value) values('DOMA','&&domain');
insert into CONFIGURATION(configuration, value) values('WALLE','/opt/oracle/admin/ORCLCDB/wallet');
insert into CONFIGURATION(configuration, value) values('WALPS','WalletPasswd123');
insert into CONFIGURATION(configuration, value) values('URLPO','api/v1/user/firstLoginToday');
