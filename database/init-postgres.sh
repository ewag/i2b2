#!/usr/bin/env bash
## Initialise database, not with data, but with i2b2 uesrs and privileges
## To override variables (eg passwords), run me like so:
## PGI2B2ADMINPASS=admin PGI2B2USERPASS=user ./init-db.sh

set -e
set -u

RUNPSQLUSER=${RUNPSQLUSER-postgres}
PGUSER=${PGUSER-postgres}
PGHOST=${PGHOST-localhost}
PGI2B2ADMINPASS=${DB_ADMIN_PASS-defaultverybadpassword}
PGI2B2USERPASS=${DB_USER_PASS-defaultbadpassword}
DS_PM_PASS=${DS_PM_PASS-${PGI2B2USERPASS}}
DS_WD_PASS=${DS_WD_PASS-${PGI2B2USERPASS}}
DS_HIVE_PASS=${DS_HIVE_PASS-${PGI2B2USERPASS}}
DS_CRC_PASS=${DS_CRC_PASS-${PGI2B2USERPASS}}
DS_ONT_PASS=${DS_ONT_PASS-${PGI2B2USERPASS}}
INCLUDE_DEMO_DATA=${INCLUDE_DEMO_DATA-False}
i2b2_PROJECT_NAME=${PROJECT_NAME-Dummy project}

i2b2_user_pass=${i2b2_user_pass-$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n 1)}
i2b2_service_pass=${i2b2_service_pass-$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n 1)}

# >&2 echo -e "Using passwords:\nPGI2B2ADMINPASS=${PGI2B2ADMINPASS}\nPGI2B2USERPASS=${PGI2B2USERPASS}" #DEBUG
# >&2 echo -e "Using i2b2_PROJECT_NAME: ${i2b2_PROJECT_NAME}" #DEBUG

RUN_PSQL="sudo -u ${RUNPSQLUSER} psql \
    -h ${PGHOST} \
    --set AUTOCOMMIT=on \
    --set PGI2B2ADMINPASS='${PGI2B2ADMINPASS}' \
    --set PGI2B2USERPASS='${PGI2B2USERPASS}' \
    --set DS_PM_PASS='${DS_PM_PASS}' \
    --set DS_WD_PASS='${DS_WD_PASS}' \
    --set DS_HIVE_PASS='${DS_HIVE_PASS}' \
    --set DS_CRC_PASS='${DS_CRC_PASS}' \
    --set DS_ONT_PASS='${DS_ONT_PASS}'"
## Cannot add here due to quoting/space escaping problems...
#    --set i2b2_PROJECT_NAME='${i2b2_PROJECT_NAME}' \

function run_and_check_sql() {
    ## Run SQL file against i2b2 database.
    ## "ACTIVE_USER (arg $2)" determines which scheme is used
    ## $3 ignore errors?
    PGFILE_PATH=""
    if test -f $1; then
        PGFILE_PATH=${1}
    else
        echo >&2 "WARNING: Not a real file (skipping...): ${1}"
        return 0
    fi
    ACTIVE_USER=${2-${PGUSER}}
    ERROR_STOP="on"
    if (( $# >= 3 )) &&  [ $3 != "0" ] ; then
        echo >&2 "Ignoring SQL errors!"
        ERROR_STOP="off"
    fi
    >&2 echo "Importing SQL data as user '${ACTIVE_USER}' from file: ${PGFILE_PATH}"
    ${RUN_PSQL} -U${ACTIVE_USER} \
        -f ${PGFILE_PATH} \
        --set ON_ERROR_STOP=${ERROR_STOP} \
        --set i2b2_PROJECT_NAME="${i2b2_PROJECT_NAME}" \
        i2b2

    psql_exit_status=$?

    if [ $psql_exit_status != 0 ]; then
        echo "psql failed while trying to run this sql script" >&2
        exit $psql_exit_status
    fi
}

echo "Running custom SQL initialisation..." | tee /dev/stderr
sudo -u ${RUNPSQLUSER} psql -X --echo-all --set AUTOCOMMIT=on -c "CREATE DATABASE i2b2;";
## CUSTOM_PGFILES is a list of the SQL files to run through building up the database structure
CUSTOM_PGFILES='setup-users.sql setup-schema.sql'
current_path="./initdb.d"
for PGFILE in $CUSTOM_PGFILES; do
    run_and_check_sql "${current_path}/${PGFILE}"
done

if [ ${INCLUDE_DEMO_DATA} == "True" ]; then
    echo "Running i2b2 SQL setup (with demo data)..." | tee /dev/stderr
else
    echo "Running i2b2 SQL setup (without demo data)..." | tee /dev/stderr
fi

echo "Building i2b2 'CRC' structure..." | tee /dev/stderr
current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Crcdata/scripts"
for SQL_FILE in "${current_path}"/crc_create_*; do
    if $(echo ${SQL_FILE} | grep -iq "postgres"); then
        run_and_check_sql "${SQL_FILE}" "i2b2demodata"
    fi
done
## generate list: grep "<transaction src=\"./scripts/procedures/\${db.type}/" ./Crcdata/data_build.xml | cut -d\" -f2 | cut -d/ -f5 | tr '\n' ' '
ordered_run_list="CREATE_TEMP_CONCEPT_TABLE.sql CREATE_TEMP_PATIENT_TABLE.sql CREATE_TEMP_PID_TABLE.sql CREATE_TEMP_EID_TABLE.sql CREATE_TEMP_PROVIDER_TABLE.sql CREATE_TEMP_TABLE.sql CREATE_TEMP_VISIT_TABLE.sql INSERT_CONCEPT_FROMTEMP.sql INSERT_ENCOUNTERVISIT_FROMTEMP.sql INSERT_PATIENT_MAP_FROMTEMP.sql INSERT_PATIENT_FROMTEMP.sql INSERT_PID_MAP_FROMTEMP.sql INSERT_EID_MAP_FROMTEMP.sql INSERT_PROVIDER_FROMTEMP.sql REMOVE_TEMP_TABLE.sql UPDATE_OBSERVATION_FACT.sql SYNC_CLEAR_CONCEPT_TABLE.sql SYNC_CLEAR_PROVIDER_TABLE.sql UPDATE_QUERYINSTANCE_MESSAGE.sql CREATE_TEMP_MODIFIER_TABLE.sql INSERT_MODIFIER_FROMTEMP.sql SYNC_CLEAR_MODIFIER_TABLE.sql"
for SQL_FILE in ${ordered_run_list}; do
    run_and_check_sql "${current_path}/procedures/postgresql/${SQL_FILE}" "i2b2demodata"
done

if [ ${INCLUDE_DEMO_DATA} != "True" ]; then
    ## Load demographics demo data only!
    DEMO_PATH="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Crcdata/scripts/demo/postgresql"

    bash -c "cd ${DEMO_PATH} && unzip *.zip"
    ## remove US zip codes - its lots of data and no use to us here (this speeds up load time!)
    cd ${DEMO_PATH} &&  awk 'NR==FNR{if (/\\i2b2\\Demographics\\Zip codes/) del[NR-1] del[NR]; next} !(FNR in del)' concept_dimension_demo_insert_data.sql concept_dimension_demo_insert_data.sql | grep -B1 'i2b2\\Demographics' > clean_demographics.sql && cd -
    run_and_check_sql "${DEMO_PATH}/clean_demographics.sql" "i2b2demodata" "true"
    bash -c "cd ${DEMO_PATH} && rm -f *.sql"
fi

echo "Building i2b2 'Hive' structure..." | tee /dev/stderr
current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Hivedata/scripts"
run_and_check_sql "${current_path}/create_postgresql_i2b2hive_tables.sql" "i2b2hive"
ordered_run_list="work_db_lookup_postgresql_insert_data.sql ont_db_lookup_postgresql_insert_data.sql crc_db_lookup_postgresql_insert_data.sql im_db_lookup_postgresql_insert_data.sql"
for SQL_FILE in ${ordered_run_list}; do
    run_and_check_sql "${current_path}/${SQL_FILE}" "i2b2hive"
done

echo "Building i2b2 'im' structure..." | tee /dev/stderr
## Nothing to do here...

echo "Building i2b2 'MetaData' structure..." | tee /dev/stderr
current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Metadata/scripts"
run_and_check_sql "${current_path}/create_postgresql_i2b2metadata_tables.sql" "i2b2metadata"
for SQL_FILE in "${current_path}"/procedures/postgresql/*.sql; do
    run_and_check_sql "${SQL_FILE}" "i2b2metadata"
done
if [ ${INCLUDE_DEMO_DATA} != "True" ]; then
    ## Load demographics only!
    current_path="./initdb.d/"
    run_and_check_sql "${current_path}/setup-demographics-metadata.sql" "i2b2metadata"

    DEMO_PATH="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Metadata/demo/scripts/postgresql"
    bash -c "cd ${DEMO_PATH} && unzip *.zip"
    # run_and_check_sql "${DEMO_PATH}/i2b2_metadata_insert_data.sql" "i2b2metadata" "true" ## TODO: Maybe not needed?
    ## remove US zip codes - its lots of data and no use to us here (this speeds up load time!)
    cd ${DEMO_PATH} && awk 'NR==FNR{if (/\\i2b2\\Demographics\\Zip codes/) del[NR-1] del[NR]; next} !(FNR in del)' i2b2_metadata_demographics_insert_data.sql i2b2_metadata_demographics_insert_data.sql > clean_demographics.sql && cd -
    run_and_check_sql "${DEMO_PATH}/clean_demographics.sql" "i2b2metadata" "true"
    bash -c "cd ${DEMO_PATH} && rm -f *.sql"
fi

echo "Building i2b2 'PM' structure..." | tee /dev/stderr
current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Pmdata/scripts"
run_and_check_sql "${current_path}/create_postgresql_i2b2pm_tables.sql" "i2b2pm"
run_and_check_sql "${current_path}/create_postgresql_triggers.sql" "i2b2pm"

echo "Building i2b2 'Workdata' structure..." | tee /dev/stderr
current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Workdata/scripts"
run_and_check_sql "${current_path}/create_postgresql_i2b2workdata_tables.sql" "i2b2workdata"
run_and_check_sql "${current_path}/workplace_access_demo_insert_data.sql" "i2b2workdata"

if [ ${INCLUDE_DEMO_DATA} != "True" ]; then
    current_path="./initdb.d"
    echo "Fixing default i2b2 data..." | tee /dev/stderr
    run_and_check_sql "${current_path}/repair-data.sql" "i2b2" "true"
    echo "Setting up project access..." | tee /dev/stderr
    run_and_check_sql "${current_path}/setup-project.sql" "i2b2" "true"
fi

## Setting PASSWORDS
## Default (or any) password (eg) "demouser" can be hashed like: `echo -n "demouser" | md5sum | cut -d" " -f1` ## NOTE: This is not salted and md5 is very weak!
## Source: https://github.com/i2b2/i2b2-core-server/blob/056970dfcbd24cd1af5bb35e215eb6b71b9b44f7/edu.harvard.i2b2.pm/src/edu/harvard/i2b2/pm/util/PMUtil.java#L173
## https://stackoverflow.com/questions/30496061/why-not-use-md5-for-password-hashing


## WARNING! The MD5 hash generated by java in the wildfly container doesn't always match a correct MD5 hash, often its' only 31 chars long, usually missing a zero
## WARNING! This means usually at least one of the users' passwords doesn't work
## TODO: See if a java library can be updated to make passwords more reliable? Compatibility with existing passwords? - Maybe get the same library in this container for this process?
# dbtime=$(date +"%Y-%m-%d %T")
# ## Set the 'AGG_SERVICE_ACCOUNT' password
# echo >&2 "Setting 'AGG_SERVICE_ACCOUNT' password as: '${i2b2_service_pass}'"
# hashed_pass=$(echo -n "${i2b2_service_pass}" | md5sum | cut -d" " -f1)
# sudo -u postgres psql -Ui2b2pm -X --echo-all --set AUTOCOMMIT=on -c "\
# UPDATE pm_user_data SET password='${hashed_pass}', change_date='${dbtime}.617', changeby_char='i2b2' WHERE user_id = 'AGG_SERVICE_ACCOUNT'; \
# " i2b2
# sudo -u postgres psql -Ui2b2hive -X --echo-all --set AUTOCOMMIT=on -c "\
# update i2b2hive.hive_cell_params set value='${i2b2_service_pass}' where param_name_cd='edu.harvard.i2b2.crc.pm.serviceaccount.password'; \
# " i2b2
# ## Set the 'i2b2' (admin) password
# echo >&2 "Setting 'i2b2' password as: '${i2b2_user_pass}'"
# hashed_pass=$(echo -n "${i2b2_user_pass}" | md5sum | cut -d" " -f1)
# sudo -u postgres psql -Ui2b2pm -X --echo-all --set AUTOCOMMIT=on -c "\
# UPDATE pm_user_data SET password='${hashed_pass}', change_date='${dbtime}.001', changeby_char='i2b2' WHERE user_id = 'i2b2'; \
# " i2b2

## WIP: If INCLUDE_DEMO_DATA=True, add demo data
if [ ${INCLUDE_DEMO_DATA} == "True" ]; then
    echo "WIP: Loading demo data (at user's request - env var: INCLUDE_DEMO_DATA=${INCLUDE_DEMO_DATA})" | tee /dev/stderr
    echo "This could take some time..." | tee /dev/stderr
    ## Crcdata
    demo_data_paths=" \
        /docker-entrypoint/i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Crcdata/scripts/demo/postgresql \
    "
    for DEMO_PATH in ${demo_data_paths}; do
        bash -c "cd ${DEMO_PATH} && unzip *.zip"
        for SQL_FILE in "${DEMO_PATH}"/*.sql; do
            run_and_check_sql "${SQL_FILE}" "i2b2demodata" "true"
        done
        bash -c "cd ${DEMO_PATH} && rm -f *.sql"
    done
    ## Hivedata
    current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Hivedata/scripts"
    demo_data_files=" \
        crc_db_lookup_postgresql_insert_data.sql \
        im_db_lookup_postgresql_insert_data.sql \
        ont_db_lookup_postgresql_insert_data.sql \
        work_db_lookup_postgresql_insert_data.sql \
    "
    for SQL_FILE in ${demo_data_files}; do
        run_and_check_sql "${current_path}/${SQL_FILE}" "i2b2hive" "true"
    done
    ## Imdata
    current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Imdata/scripts/postgresql"
    for SQL_FILE in "${current_path}"/*; do
        run_and_check_sql "${SQL_FILE}" "i2b2imdata" "true"
    done
    ordered_run_list="im_mpi_demographics_insert_data.sql im_mpi_mapping_insert_data.sql im_project_patients_insert_data.sql im_project_sites_insert_data.sql"
    for SQL_FILE in ${ordered_run_list}; do
        run_and_check_sql "${current_path}/${SQL_FILE}" "i2b2imdata" "true"
    done
    ## Metadata
    current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Metadata/demo/scripts"
    ordered_run_list="schemes_insert_data.sql table_access_insert_data.sql"
    for SQL_FILE in ${ordered_run_list}; do
        run_and_check_sql "${current_path}/${SQL_FILE}" "i2b2metadata"
    done
    demo_data_paths=" \
        /docker-entrypoint/i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Metadata/demo/scripts/postgresql \
    "
    for DEMO_PATH in ${demo_data_paths}; do
        bash -c "cd ${DEMO_PATH} && unzip *.zip"
        for SQL_FILE in "${DEMO_PATH}"/*.sql; do
            run_and_check_sql "${SQL_FILE}" "i2b2metadata" "true"
        done
        bash -c "cd ${DEMO_PATH} && rm -f *.sql"
    done

    ## Pmdata
    current_path="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Pmdata/scripts/demo"
    run_and_check_sql "${current_path}/pm_access_insert_data.sql" "i2b2pm" "true"
    demo_data_paths=" \
        /docker-entrypoint/i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Pmdata/scripts/demo \
    "
    for DEMO_PATH in ${demo_data_paths}; do
        for SQL_FILE in "${DEMO_PATH}"/*.sql; do
            run_and_check_sql "${SQL_FILE}" "i2b2pm" "true"
        done
    done
    ## Workdata
    SQL_FILE="./i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/Workdata/scripts/workplace_access_demo_insert_data.sql"
    run_and_check_sql "${SQL_FILE}" "i2b2workdata" "true"

    echo "Fixing default i2b2 data..." | tee /dev/stderr
    current_path="./initdb.d/"
    run_and_check_sql "${current_path}/repair-data.sql" "i2b2" "true"

fi

## TODO: See password setting problem above
# echo >&2 "Reminder: 'i2b2' password = '${i2b2_user_pass}'"
# echo >&2 "Reminder: 'AGG_SERVICE_ACCOUNT' password = '${i2b2_service_pass}'"
echo "Please change the passwords for the following 2 users!" | tee /dev/stderr
echo "i2b2: demouser" | tee /dev/stderr
echo "AGG_SERVICE_ACCOUNT: demouser (see README for additional steps!)" | tee /dev/stderr

echo "$(date): SQL script(s) successful" | tee /dev/stderr
exit 0
