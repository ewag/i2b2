-- setup-schema.sql --
-- PostgreSQL setup for i2b2...

\connect i2b2

CREATE SCHEMA i2b2demodata AUTHORIZATION i2b2demodata ;
CREATE SCHEMA i2b2hive AUTHORIZATION i2b2hive ;
CREATE SCHEMA i2b2imdata AUTHORIZATION i2b2imdata; 
CREATE SCHEMA i2b2metadata AUTHORIZATION i2b2metadata ;
CREATE SCHEMA i2b2pm AUTHORIZATION i2b2pm ;
CREATE SCHEMA i2b2workdata AUTHORIZATION i2b2workdata;
