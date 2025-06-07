@echo off

REM Create directories
if not exist "data" mkdir data
if not exist "jars" mkdir jars
if not exist "results" mkdir results

REM Check if dataset exists
if not exist "data\access_log_Jul95" (
    echo Extracted dataset not found. Checking for compressed file...
    if not exist "data\NASA_access_log_Jul95.gz" (
        echo Compressed file not found. Downloading dataset...
        curl -o data\NASA_access_log_Jul95.gz ftp://ita.ee.lbl.gov/traces/NASA_access_log_Jul95.gz
    )
    echo Extracting dataset...
    powershell -Command "& {$input = [System.IO.File]::OpenRead('data\NASA_access_log_Jul95.gz'); $output = [System.IO.File]::Create('data\NASA_access_log_Jul95'); $gzip = New-Object System.IO.Compression.GzipStream($input, [System.IO.Compression.CompressionMode]::Decompress); $gzip.CopyTo($output); $gzip.Close(); $output.Close(); $input.Close()}"
    REM Extract only well-formed log entries (7-10 fields) - using PowerShell
    powershell -Command "& {Get-Content 'data\NASA_access_log_Jul95' | ForEach-Object { $fields = $_ -split '\s+'; if ($fields.Count -ge 7 -and $fields.Count -le 10) { $_ } } | Out-File -FilePath 'data\access_log_Jul95' -Encoding ASCII}"
) else (
    echo Dataset already extracted. Skipping download and extraction.
)

REM Stop and remove containers, networks, images, and volumes
docker compose down -v

REM Build the hadoop-client image
docker compose build hadoop-client

REM Remove the NameNode directory
docker compose run --rm --user root namenode rm -rf /opt/hadoop/dfs/name/*

REM Change ownership of the namenode data directory
docker compose run --rm --user root namenode chown -R 1000:1000 /opt/hadoop/dfs/name

docker compose run --rm namenode hdfs namenode -format -force

docker compose run --rm --user root datanode rm -rf /opt/hadoop/dfs/data/*
docker compose run --rm --user root datanode chown -R 1000:1000 /opt/hadoop/dfs/data

docker compose run --rm --user root datanode2 rm -rf /opt/hadoop/dfs/data/*
docker compose run --rm --user root datanode2 chown -R 1000:1000 /opt/hadoop/dfs/data

REM Start the containers in detached mode
docker compose up -d

REM Execute the run-jobs.sh script inside the hadoop-client container
docker compose exec hadoop-client /opt/hadoop/scripts/run-jobs.sh

echo Initial script finished. Check Docker Desktop for container status.