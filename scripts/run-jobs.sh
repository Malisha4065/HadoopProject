#!/bin/bash

echo "=== Hadoop MapReduce Java Jobs Runner ==="
echo "Starting jobs at $(date)"

echo "Waiting for Hadoop services..."
sleep 10

# Wait for NodeManagers to be active
echo "Waiting for NodeManagers to register with ResourceManager..."
MAX_RETRIES=30 # Wait for up to 5 minutes (30 * 10 seconds)
RETRY_COUNT=0
while true; do
    # Count active NodeManagers in RUNNING state. Output of 'yarn node -list' can vary.
    # This awk script tries to be robust: skips 2 header lines, checks 2nd field for "RUNNING".
    NUM_ACTIVE_NODES=$(yarn node -list 2>/dev/null | awk 'NR > 2 && $2 == "RUNNING" {count++} END {print count+0}')
    
    if [ "$NUM_ACTIVE_NODES" -ge 1 ]; then
        echo "Found $NUM_ACTIVE_NODES active NodeManager(s)."
        yarn node -list # Display node status
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "Timeout waiting for NodeManagers. Cluster may not have enough resources or NodeManagers failed to start/register."
        echo "Current NodeManager status:"
        yarn node -list 2>/dev/null || echo "Failed to get NodeManager list from ResourceManager."
        echo "Please check YARN ResourceManager and NodeManager logs for errors."
        exit 1
    fi
    
    echo "No active NodeManagers found yet. Retrying in 10 seconds... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 10
done

# Set log4j configuration explicitly
export HADOOP_ROOT_LOGGER=WARN,console

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
    
    echo "Extracting top 1000 IP addresses and domains..."
    hdfs dfs -cat /output/top_ips/part-* | sort -k2 -nr | head -1000 > /opt/hadoop/results/top_ips_combined.txt

    # Extract IPs
    grep "^IP:" /opt/hadoop/results/top_ips_combined.txt | sed 's/^IP://' > /opt/hadoop/results/top_ips_only.txt

    # Extract domains
    grep "^DOMAIN:" /opt/hadoop/results/top_ips_combined.txt | sed 's/^DOMAIN://' > /opt/hadoop/results/top_domains_only.txt

    echo "Results saved"
    
    echo "Top 10 IP addresses and domains:"
    head -10 /opt/hadoop/results/top_ips_combined.txt
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