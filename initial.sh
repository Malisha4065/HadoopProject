#!/bin/bash

mkdir -p data
mkdir -p jars
mkdir -p results

if [ ! -f data/access_log_Jul95 ]; then
    echo "Extracted dataset not found. Checking for compressed file..."
    if [ ! -f data/NASA_access_log_Jul95.gz ]; then
        echo "Compressed file not found. Downloading dataset..."
        curl -o data/NASA_access_log_Jul95.gz ftp://ita.ee.lbl.gov/traces/NASA_access_log_Jul95.gz
    fi
    echo "Extracting dataset..."
    gunzip -c data/NASA_access_log_Jul95.gz > data/NASA_access_log_Jul95
    # Extract only well-formed log entries (7-10 fields)
    awk 'NF>=7 && NF<=10' data/NASA_access_log_Jul95 > data/access_log_Jul95
else
    echo "Dataset already extracted. Skipping download and extraction."
fi

# Stop and remove containers, networks, images, and volumes
docker compose down -v

# Build the hadoop-client image
docker compose build hadoop-client

# Remove the NameNode directory
docker compose run --rm --user root namenode rm -rf /opt/hadoop/dfs/name/*

# Change ownership of the namenode data directory
docker compose run --rm --user root namenode chown -R 1000:1000 /opt/hadoop/dfs/name

docker compose run --rm namenode hdfs namenode -format -force

docker compose run --rm --user root datanode rm -rf /opt/hadoop/dfs/data/*
docker compose run --rm --user root datanode chown -R 1000:1000 /opt/hadoop/dfs/data

docker compose run --rm --user root datanode2 rm -rf /opt/hadoop/dfs/data/*
docker compose run --rm --user root datanode2 chown -R 1000:1000 /opt/hadoop/dfs/data

# Start the containers in detached mode
docker compose up -d

# Execute the run-jobs.sh script inside the hadoop-client container
docker compose exec hadoop-client /opt/hadoop/scripts/run-jobs.sh
