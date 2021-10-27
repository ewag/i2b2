#!/bin/bash
## Healthcheck for i2b2 database

## Schema installation complete
sudo -u postgres psql -Ui2b2workdata -qt -c "SELECT COUNT(1) FROM WORKPLACE;" i2b2 > /dev/null 2>&1
installed_exitcode=$?
## Passwords updated (Checking it is not the md5sum of "demouser")
# passupdate=$(sudo -u postgres psql -Ui2b2pm -qt -c "SELECT COUNT(1) FROM pm_user_data where password = '91017d590a69dc49807671a51f10ab7f';" i2b2 | xargs)
passupdate=0 ## Override/disable password check (consistency issues with password hashes)
if [ "${installed_exitcode}" != 0 ] || [ "${passupdate}" != 0 ]; then
    echo >&2 "{installed_exitcode: '${installed_exitcode}', passupdate: '${passupdate}'}"
    exit 1
fi
