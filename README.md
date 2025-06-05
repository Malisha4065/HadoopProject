# Analysing Top IP Addresses and Error codes using Apache Hadoop

Using NASA web server logs of July 95 [Dataset link](https://ita.ee.lbl.gov/html/contrib/NASA-HTTP.html) top IP addresses and error codes were extracted using Apache Hadoop. Map reducing logic was implemented in Java.

## Hadoop Cluster with Hadoop Yarn for resource management was custom configured using original apache/hadoop:3.4.1 docker image

Feel free to use the configuration. Note that the bash/batch scripts in this repository are written for the map-reducing task mentioned above.


### Linux
```bash
./initial.sh
```

### Windows

## make sure to convert compile.sh and run-jobs.sh inside the scripts folder to LF format before running the script
```bash
.\initial.bat
```
