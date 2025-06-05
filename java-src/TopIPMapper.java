import java.io.IOException;
import java.util.regex.Pattern;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class TopIPMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
    
    private final static IntWritable one = new IntWritable(1);
    private Text ipAddressOrDomain = new Text();
    
    // Pattern to validate IP addresses
    private static final Pattern IP_PATTERN = Pattern.compile(
        "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}" +
        "([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$");
    
    // Pattern to validate domain names
    private static final Pattern DOMAIN_PATTERN = Pattern.compile(
        "^(?!-)[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$");
    
    @Override
    public void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // Split the log line by whitespace
            String[] fields = line.split("\\s+");
            
            // Ensure minimum required fields (8+ for NASA logs)
            if (fields.length >= 8) {
                String firstField = fields[0];
                
                // Check if it's an IP address
                if (IP_PATTERN.matcher(firstField).matches()) {
                    ipAddressOrDomain.set("IP:" + firstField);  // Prefix with "IP:"
                    context.write(ipAddressOrDomain, one);
                }
                // Check if it's a domain name
                else if (DOMAIN_PATTERN.matcher(firstField).matches()) {
                    ipAddressOrDomain.set("DOMAIN:" + firstField);  // Prefix with "DOMAIN:"
                    context.write(ipAddressOrDomain, one);
                }
            }
        } catch (Exception e) {
            System.err.println("Error processing line: " + line);
        }
    }
}