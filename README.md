
# Basic usage
The first step is to clone the git repo with the setup information:
git clone #### TODO:
> _NOTE:_ This can be limited to only the `docker-compose.yml` and `.env` files if you prefer to keep it small. The other files in the repo are only required for building the images, which is done for us by github.

Then we recommend making a few small adjustments to the settings and providing some "secrets". Secrets are a term docker uses for private configuration values. The way they are stored and used provides separation from regular environment variables.

## Adjust your .env
The directory has a `.env` file which is used by docker to put environment variables into the containers. It also allows the `docker compose` process to use them which can aid deployments. The .env provided covers a range of variables i2b2 can use, most of which will not need changing. For setting up on a remote server, the relevant fields should be changed.

## Create your secrets
The `secrets/` directory holds plain text files with sensitive information, usually passwords, which i2b2 uses. In our setup, these are loaded as env variables at container runtime, in a more protected way than simply providing them docker as env vars. These are either referenced from the `.env` file by variables ending "_FILE" or as additional file called `ENV_MULTILOAD.txt` which is sourced by the container at runtime. For obvious reasons, this is not provided in the repository, you must create this yourself. eg:
```sh
mkdir secrets; cd secrets; touch DB_ADMIN_PASS.txt DB_USER_PASS.txt POSTGRES_PASSWORD.txt ENV_MULTILOAD.txt; cd ..
```
Then add information as described above, where the files referenced by `.env` should be individual passwords, eg `DB_ADMIN_PASS.txt`:
```txt
MySecurePassword
```

and `ENV_MULTILOAD.txt` file could look like:
```sh
export DS_PM_PASS=pm-pass
export DS_WD_PASS=wd-pass
...
```

## Deploy containers
Once all the settings are done, you can deploy the containers to your system. This follows regular docker commands so no special setup should be needed. From the base directory of the project (where you have the `docker-compose.yml` file), run the following:
```sh
docker compose up -d
```
After a short while, three containers should be running and a basic i2b2 installation available at the URL in the settings. Demo data should be loaded if you set that option in `.env`


## Change default passwords
There are 2 default users: "i2b2" and "AGG_SERVICE_ACCOUNT"

These both come with the default password "demouser". It important to change _both_ of these to reduce the risk of unwanted access. Unfortunately, the password hashing mechanism used by i2b2 is not directly re-producable in the bootstrap environment, meaning we can't (yet) set these automatically during first install, so they must be changed manually.

Login as the "i2b2" user choosing project "administration" if needed (if you've added a demo project, you should have a choice). In the menu tree, navigate to "Manage Users -> i2b2 Admin" and use the form to change the password. Login again and do the same for user "AGG_SERVICE_ACCOUNT".

An additional step is required for "AGG_SERVICE_ACCOUNT". For this, some command line and SQL familiarity is beneficial.
* Connect to your host system (where you ran `docker compose ...`)
* Connect to the database container: `docker exec -it i2b2-database bash`
* Connect to the postgres DBMS: `sudo -u postgres psql i2b2`
* Run an update command _(replacing `${newpassword}` with what you set in the web interface)_: `update i2b2hive.hive_cell_params set value='${newpassword}' where param_name_cd='edu.harvard.i2b2.crc.pm.serviceaccount.password';`

# Where is demo data
Demo data is included in the database image - we get it as an archive file from i2b2's github pages: https://github.com/i2b2/i2b2-data ([More specifically](https://codeload.github.com/i2b2/i2b2-data/tar.gz/refs/tags/v1.7.12a.0001))

Only the "NewInstall" section is included and located (within the database container) at: `/docker-entrypoint/i2b2-data/edu.harvard.i2b2.data/Release_1-7/NewInstall/`

Using the `INCLUDE_DEMO_DATA=True` setting in the `.env` file, the demo data parts of this will automatically be installed, but the data can be accessed and run manually at any time after the containers and database structure have already been created.

> _NOTE:_ This process is currently not fully operational, the demo data is not loaded cleanly and is not accessible using the interface

# Custom breakdowns
This is an i2b2 concern, so we won't repeat their information here, but rather link to the [relevant documentation](https://community.i2b2.org/wiki/display/RM/1.7.10+Release+Notes#id-1.7.10ReleaseNotes-SQLQueryBreakdowns) from i2b2.

# How to copy files to into docker container
It is likely you will want to copy a file into the container at some point, for example SQL files to configure custom breakdowns. While this is not strictly good docker practice, it can be the most pragmatic option. This is achieved with a command similar to this from the host server (where you originally ran `docker compose ...`):
```sh
docker cp my-breakdown.sql i2b2-database:/tmp/
```

> _NOTE:_ Depending in your environment, allowing remote access directly to the database could be a nicer option. You would need to tell docker to expose the database ports. Follow the structure of "ports:" in the "i2b2-web" section of `docker-compose.yml`

# Docker volumes
Docker uses "volumes" when persistant data should be stored, eg in the case of databases. This is essentially a directory on the host filesystem which is mounted as part of the container filesystem, meaning container re-creation does not affect the data.

## Where they're stored
By default, docker will place volumes under `/var/lib/docker/volumes/` on a posix system, the access to this under windows (even with WSL2) is different and outside the scope of this document. In case your docker system uses a different location you can check the docker root, which will contain a "volumes/" directory with:
```sh
docker info | grep "Docker Root Dir:"
```

## Backing up and restoring volumes
These can be copied, archived, encrypted and sent to remote storage servers should you wish to maintain backups. Here is a possible way to manage that process (while you could chose other options!)

_"docker-vol-backup.sh"_
```sh
#!/usr/bin/env bash
## Backup all docker volumes - compressed and encrypted

>&2 echo -e "Starting docker backups... [$( date -Iminutes )]"
## Get location from docker info
src_vol_path="$( docker info 2>/dev/null | grep "Docker Root Dir" | cut -d\: -f2 )/volumes/"
docker_bak_pass="/home/backups/docker-config/secrets/backup_secret"
vol_backup_path="/home/backups/docker-backups/"
max_age=5 ## in days

cd $src_vol_path
vol_list=$( ls -1 ./ )
while read VOL; do
  if [ -d $VOL ] ; then
    >&2 echo "Backing up $VOL..."
    tar -cpz "$VOL" | openssl enc -aes-256-cbc -e -kfile "$docker_bak_pass" 2>/dev/null > ${vol_backup_path}$( basename "$VOL")_$( date -Iminutes )_${mode:-MANUAL}.tar.gz.enc
  fi
done <<< "$vol_list"

## Cleanup older backups
>&2 echo "Cleaning backups older than $max_age days"
cd $vol_backup_path
find $vol_backup_path -mindepth 1 -mtime +$max_age -delete
>&2 echo "Nightly docker backups complete [$( date -Iminutes )]"
```
> NOTE:_ Assumptions are made in this script about a "backups" user existing and the directory structure. This is run on the docker host and is not a related part of the docker system. We provide this example as a basic starting point

Also add a cron file, eg `/etc/cron.d/dockerbackup`
```sh
20 0 * * * root mode=CRON /home/backups/docker-config/docker-vol-backup.sh >>/var/log/docker-backups 2>&1
# Trigger the docker volume backup every night
```
### Restore
While the backup archive filename will contain metadata about the time of the backup, for readability, we copy the original backup archive to a simpler filename before restoring:
```sh
mv <dir_name>_<BAK_INFO>.tar.gz.enc <dir_name>_restore.tar.gz.enc
openssl enc -aes-256-cbc -d -in <dir_name>_restore.tar.gz.enc | tar xvzf <target_dir_name>
```
This will restore the archive data to the volume location (target_dir_name) - this is uaually best done while the container is stopped. Then the container can be restarted.
