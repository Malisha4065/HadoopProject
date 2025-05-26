#!/bin/bash

echo "=== Compiling Java MapReduce Jobs ==="

cd /opt/hadoop/java-src

HADOOP_CP=$(hadoop classpath)
if [ $? -ne 0 ] || [ -z "$HADOOP_CP" ]; then
    echo "Failed to get Hadoop classpath. Ensure Hadoop is running and configured, and 'hadoop' command is in PATH."
    exit 1
fi

echo "Current Hadoop Classpath: $HADOOP_CP"

echo "Compiling Top IP Analysis..."
javac -cp "$HADOOP_CP" -source 1.8 -target 1.8 TopIP*.java
if [ $? -eq 0 ]; then
    jar cf /opt/hadoop/jars/topip.jar TopIP*.class
    echo "Top IP Analysis compiled successfully"
else
    echo "Failed to compile Top IP Analysis"
    exit 1
fi

echo "Compiling Error Analysis..."
javac -cp "$HADOOP_CP" -source 1.8 -target 1.8 ErrorAnalysis*.java
if [ $? -eq 0 ]; then
    jar cf /opt/hadoop/jars/erroranalysis.jar ErrorAnalysis*.class
    echo "Error Analysis compiled successfully"
else
    echo "Failed to compile Error Analysis"
    exit 1
fi

echo "All Java classes compiled successfully!"
echo "JAR files created in /opt/hadoop/jars/"
ls -la /opt/hadoop/jars/

rm -f *.class

echo "Compilation completed at $(date)"