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
            
            if (fields.length >= 9) {
                String status = fields[8];  // Status code is typically at index 8
                
                // Focus on error codes (4xx and 5xx)
                if (status.startsWith("4") || status.startsWith("5")) {
                    statusCode.set(status);
                    context.write(statusCode, one);
                }
            }
        } catch (Exception e) {
            System.err.println("Error processing line: " + line);
        }
    }
}