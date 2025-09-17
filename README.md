# Demo of app consistent backups w/ Postgres

Playground example of creating app consistent backups of Postgres DBs. Input csv for postgres table is modified_avocado_prices.csv. The demo involves two docker containers, a postgreSQL DB container to host the DB and an alpine linux DB responsible for attempting to do an application consistent full backup of the Postgres DB using pg_dump. 

Do not use this project as-is for production.

## Pre-reqs

Instructions below assume you're running the project on a Linux OS with Docker installed.

## Steps

- Create a `.env` file and set each of the fields
```
POSTGRES_USER= # SET HERE
POSTGRES_PASSWORD= # SET HERE
POSTGRES_DB=mydb 
POSTGRES_ADDR=172.18.0.10
```

- Modify the `cronjob` file to the frequency a backup should be created for the DB. Existing frequency is every 6 hours on the hour.
```
echo "0 */6 * * * /usr/local/bin/pgdump-cron.sh >> /var/log/pgdump-cron.log 2>&1" > /etc/crontabs/root
```

- Start up the docker containers `docker compose up -d`
- Install the psql client on your host machine `sudo apt install postgresql-client`
- Connect to your DB `source .env && psql -d $POSTGRES_DB -h localhost -p 5432 -U $POSTGRES_USER`. Enter your password set in the .env file
- Create a table for avocado prices
```
CREATE TABLE public.avocado_prices (
    id integer,
    date date,
    averageprice numeric,
    "Total Volume" numeric,
    idk0 numeric,
    idk1 numeric,
    idk2 numeric,
    "Total Bags" numeric,
    "Small Bags" numeric,
    "Large Bags" numeric,
    "XLarge Bags" numeric,
    type text,
    year integer,
    region text
);
```
- Copy the contents of the csv file into the Postgres DB
```
\copy avocado_prices FROM `./modified_avocado_prices.csv` CSV HEADER;
```
- Check the count of the records in the avocado_prices table `SELECT COUNT(*) FROM avocado_prices;`. It should be 18250.
- Logout of the psql session (Ctrl+D). 
- Force the backup of the database with `docker exec pgdump_cron /usr/local/bin/pgdump-cron.sh`
- Check that a sql.gz file was added to the backups/ directory. `ls -l backups/`
- Change the permission of the backup copies on the host OS `sudo chown -R $USER backups/`
- Unzip the gzip of the backup you want to restore. `gzip -d -c backups/backups_20250917_032654.sql.gz > backups/backup_to_restore.sql # CHANGE TO YOUR BACKUP SQL.GZ`
- Create a second postgres docker container
```
docker run -d \ 
  --name postgres2 \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -p 5433:5432 \
  -v "$(pwd)/pgdata2":/var/lib/postgresql/data \
  postgres:16
```
- Restore the backup by running the commands in the `backups/backup_to_restore.sql`
```
cat backups/backup_to_restore.sql | docker exec -i postgres2 psql -U $POSTGRES_USER -d $POSTGRES_DB
```
- Connect to your second postgres instance with the psql client `psql -d $POSTGRES_DB -h localhost -p 5433 -U $POSTGRES_USER`
- Check the avocado_prices table is present `\d`
- Check the count present in the avocado_prices table of the second postgres instance. `select(count(*)) from avocado_prices;`
- Check the first few records from the avocado_prices table are consistent with the CSV file. `select * from avocado_prices limit 5;`


Congrats you created an app consistent full backup of a postgres docker container and restored it in another instance.

## Data Attribution

This project uses the Avocado Prices dataset from [Practice Datasets for Excel by Rohan Mistry](https://github.com/rohanmistry231/Practice-Datasets-for-Excel/blob/main/Avacado%20Prices/avocado.xlsx), licensed under the [MIT License](https://github.com/rohanmistry231/Practice-Datasets-for-Excel/blob/main/LICENSE).
