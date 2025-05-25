import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

public class TopIPDriver {
    
    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: TopIPDriver <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        conf.set("mapreduce.map.output.compress", "true");
        conf.set("mapreduce.map.output.compress.codec", "org.apache.hadoop.io.compress.SnappyCodec");
        
        Job job = Job.getInstance(conf, "top ip analysis");
        job.setJarByFile(TopIPDriver.class);
        
        // Set mapper and reducer classes
        job.setMapperClass(TopIPMapper.class);
        job.setCombinerClass(TopIPReducer.class);  // Use reducer as combiner for efficiency
        job.setReducerClass(TopIPReducer.class);
        
        // Set output key and value types
        job.setOutputKeyClass(Text.class);  
        job.setOutputValueClass(IntWritable.class);
        
        // Set input and output formats
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // Set input and output paths
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // Set number of reducers
        job.setNumReduceTasks(2);

        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}