#!/bin/bash

echo "=== Compiling Java MapReduce Jobs ==="

export HADOOP_CLASSPATH=$JAVA_HOME/lib/tools.jar
cd /opt/hadoop/java-src

echo "Compiling Top IP Analysis..."
hadoop com.sun.tools.javac.Main TopIP*.java
if [ $? -eq 0 ]; then
    jar cf /opt/hadoop/jars/topip.jar TopIP*.class
    echo "Top IP Analysis compiled successfully"
else
    echo "Failed to compile Top IP Analysis"
    exit 1
fi

echo "Compiling Error Analysis..."
hadoop com.sun.tools.javac.Main ErrorAnalysis*.java
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