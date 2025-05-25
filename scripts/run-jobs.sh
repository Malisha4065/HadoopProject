#!/bin/bash

echo "=== Hadoop MapReduce Java Jobs Runner ==="
echo "Starting jobs at $(date)"

echo "Waiting for Hadoop services..."
sleep 30

echo "Compiling Java classes..."
/opt/hadoop/scripts/compile.sh

if [ $? -ne 0 ]; then
    echo "Compilation failed. Exiting."
    exit 1
fi

echo "Creating HDFS directories..."
hdfs dfs -mkdir -p /input
hdfs dfs -mkdir -p /output

echo "Uploading data to HDFS..."
hdfs dfs -put /opt/hadoop/data/access_log_Jul95 /input/ 2>/dev/null || echo "File already exists in HDFS"

echo "Verifying data upload..."
hdfs dfs -ls /input/
hdfs dfs -du -h /input/

echo "=== Running Top IP Analysis Job ==="
hdfs dfs -rm -r /output/top_ips 2>/dev/null || true

start_time=$(date +%s)
hadoop jar /opt/hadoop/jars/topip.jar TopIPDriver /input/access_log_Jul95 /output/top_ips
end_time=$(date +%s)
ip_duration=$((end_time - start_time))

if [ $? -eq 0 ]; then
    echo "Top IP Analysis completed successfully in ${ip_duration} seconds"
    
    echo "Extracting top 20 IP addresses..."
    hdfs dfs -cat /output/top_ips/part-* | sort -k2 -nr | head -20 > /opt/hadoop/results/top_ips.txt
    echo "Results saved to /opt/hadoop/results/top_ips.txt"
    
    echo "Top 10 IP addresses:"
    head -10 /opt/hadoop/results/top_ips.txt
else
    echo "Top IP Analysis failed"
fi

echo "=== Running Error Analysis Job ==="
hdfs dfs -rm -r /output/errors 2>/dev/null || true

start_time=$(date +%s)
hadoop jar /opt/hadoop/jars/erroranalysis.jar ErrorAnalysisDriver /input/access_log_Jul95 /output/errors
end_time=$(date +%s)
error_duration=$((end_time - start_time))

if [ $? -eq 0 ]; then
    echo "Error Analysis completed successfully in ${error_duration} seconds"
    
    echo "Extracting error statistics..."
    hdfs dfs -cat /output/errors/part-* | sort -k2 -nr > /opt/hadoop/results/error_analysis.txt
    echo "Results saved to /opt/hadoop/results/error_analysis.txt"
    
    echo "Error code statistics:"
    cat /opt/hadoop/results/error_analysis.txt
else
    echo "Error Analysis failed"
fi

echo "=== Performance Summary ==="
echo "Top IP Analysis: ${ip_duration} seconds"
echo "Error Analysis: ${error_duration} seconds"
echo "Total execution time: $((ip_duration + error_duration)) seconds"

echo "=== HDFS Usage ==="
hdfs dfs -du -h /

echo "All jobs completed at $(date)"
echo "Check results in /opt/hadoop/results/ directory"