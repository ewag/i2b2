-- i2b2's provided setup and demo data doesn't match the default and/or normal setup of the infrastructure

-- Set correct schema
UPDATE i2b2hive.crc_db_lookup SET c_db_fullschema = 'i2b2demodata';
UPDATE i2b2hive.ont_db_lookup SET c_db_fullschema = 'i2b2metadata';
UPDATE i2b2hive.work_db_lookup SET c_db_fullschema = 'i2b2workdata';
DELETE FROM i2b2hive.crc_db_lookup where c_project_path = '/ACT/';
DELETE FROM i2b2hive.ont_db_lookup where c_project_path = 'ACT/';
DELETE FROM i2b2hive.work_db_lookup where c_project_path = 'ACT/';

-- Set correct wildfly URL
INSERT INTO i2b2pm.PM_CELL_DATA (CELL_ID, PROJECT_PATH, NAME, METHOD_CD, URL, CAN_OVERRIDE, STATUS_CD)
  VALUES('CRC', '/', 'Data Repository', 'REST', 'http://i2b2-wildfly:8080/i2b2/services/QueryToolService/', 1, 'A');
UPDATE i2b2pm.PM_CELL_DATA
  SET URL = 'http://i2b2-wildfly:8080/i2b2/services/QueryToolService/'
  WHERE CELL_ID = 'CRC';

INSERT INTO i2b2pm.PM_CELL_DATA(CELL_ID, PROJECT_PATH, NAME, METHOD_CD, URL, CAN_OVERRIDE, STATUS_CD)
  VALUES('FRC', '/', 'File Repository ', 'SOAP', 'http://i2b2-wildfly:8080/i2b2/services/FRService/', 1, 'A');
UPDATE i2b2pm.PM_CELL_DATA
  SET URL = 'http://i2b2-wildfly:8080/i2b2/services/FRService/'
  WHERE CELL_ID = 'FRC';

INSERT INTO i2b2pm.PM_CELL_DATA(CELL_ID, PROJECT_PATH, NAME, METHOD_CD, URL, CAN_OVERRIDE, STATUS_CD)
  VALUES('ONT', '/', 'Ontology Cell', 'REST', 'http://i2b2-wildfly:8080/i2b2/services/OntologyService/', 1, 'A');
UPDATE i2b2pm.PM_CELL_DATA
  SET URL = 'http://i2b2-wildfly:8080/i2b2/services/OntologyService/'
  WHERE CELL_ID = 'ONT';

INSERT INTO i2b2pm.PM_CELL_DATA(CELL_ID, PROJECT_PATH, NAME, METHOD_CD, URL, CAN_OVERRIDE, STATUS_CD)
  VALUES('WORK', '/', 'Workplace Cell', 'REST', 'http://i2b2-wildfly:8080/i2b2/services/WorkplaceService/', 1, 'A');
UPDATE i2b2pm.PM_CELL_DATA
  SET URL = 'http://i2b2-wildfly:8080/i2b2/services/WorkplaceService/'
  WHERE CELL_ID = 'WORK';

INSERT INTO i2b2pm.PM_CELL_DATA(CELL_ID, PROJECT_PATH, NAME, METHOD_CD, URL, CAN_OVERRIDE, STATUS_CD)
  VALUES('IM', '/', 'IM Cell', 'REST', 'http://i2b2-wildfly:8080/i2b2/services/IMService/', 1, 'A');
UPDATE i2b2pm.PM_CELL_DATA
  SET URL = 'http://i2b2-wildfly:8080/i2b2/services/IMService/'
  WHERE CELL_ID = 'IM';
