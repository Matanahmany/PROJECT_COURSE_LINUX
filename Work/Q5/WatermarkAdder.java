import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

public class WatermarkAdder {
    private static final String OUTPUT_DIR = "Ex5_3_pictures";
    private static final String WATERMARK_TEXT = "Matan Nahmany 206435737 && Osher Arbili 207372152";

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java WatermarkAdder <input_directory>");
            System.exit(1);
        }

        String inputDirPath = args[0];  
        File inputDir = new File(inputDirPath);
        File outputDir = new File(OUTPUT_DIR);

        if (!inputDir.exists() || !inputDir.isDirectory()) {
            System.out.println("Error: Input directory does not exist or is not a directory.");
            System.exit(1);
        }

        if (!outputDir.exists()) {
            outputDir.mkdirs();
        }

        File[] imageFiles = inputDir.listFiles((dir, name) -> 
            name.toLowerCase().endsWith(".png") || name.toLowerCase().endsWith(".jpg"));

        if (imageFiles == null || imageFiles.length == 0) {
            System.out.println("No images found in the directory.");
            return;
        }

        for (File imageFile : imageFiles) {
            processImage(imageFile, new File(outputDir, imageFile.getName()));
        }

        System.out.println("✅ Watermark added to all images. Processed files are in: " + OUTPUT_DIR);
    }

    private static void processImage(File inputFile, File outputFile) {
        try {
            BufferedImage image = ImageIO.read(inputFile);
            Graphics2D g2d = (Graphics2D) image.getGraphics();

   
            g2d.setFont(new Font("Arial", Font.BOLD, 20));
            g2d.setColor(Color.RED);
            g2d.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 0.8f));

        
            FontMetrics fontMetrics = g2d.getFontMetrics();
            int textWidth = fontMetrics.stringWidth(WATERMARK_TEXT);
            int textHeight = fontMetrics.getHeight();

            
            int x = (image.getWidth() - textWidth) / 2;
            int y = textHeight + 10;

           
            g2d.setColor(new Color(255, 255, 255, 150));
            g2d.fillRect(x - 10, y - textHeight, textWidth + 20, textHeight + 5);

            
            g2d.setColor(Color.RED);
            g2d.drawString(WATERMARK_TEXT, x, y);
            g2d.dispose();

            ImageIO.write(image, "png", outputFile);
            System.out.println("Processed: " + inputFile.getName());

        } catch (Exception e) {
            System.out.println("Error processing image " + inputFile.getName() + ": " + e.getMessage());
        }
    }
}
