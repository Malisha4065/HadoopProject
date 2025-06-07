import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class ErrorAnalysisMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
    
    private final static IntWritable one = new IntWritable(1);
    private Text statusCode = new Text();
    
    @Override
    public void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        if (line.isEmpty()) {
            return;
        }
        
        try {
            String[] fields = line.split("\\s+");
            
            if (fields.length >= 2) {
                // Get second field from the back (second-to-last field)
                String status = fields[fields.length - 2];
                
                // Validate that it's a proper 3-digit HTTP error status code (4xx or 5xx)
                if (status.matches("^[45]\\d{2}$")) {
                    statusCode.set(status);
                    context.write(statusCode, one);
                }
            }
        } catch (Exception e) {
            System.err.println("Error processing line: " + line);
        }
    }
}