@echo off
REM Stop and remove containers
docker compose down

REM Build the hadoop-client image
docker compose build hadoop-client

REM Change ownership of the namenode data directory
docker compose run --rm --user root namenode chown -R 1000:1000 /opt/hadoop/dfs/name

docker compose run --rm --user root datanode rm -rf /opt/hadoop/dfs/data
docker compose run --rm namenode hdfs namenode -format

REM Start the containers
docker compose up -d

REM Execute the run-jobs.sh script inside the hadoop-client container
docker compose exec hadoop-client /opt/hadoop/scripts/run-jobs.sh

echo "Initial script finished. Check Docker Desktop for container status."