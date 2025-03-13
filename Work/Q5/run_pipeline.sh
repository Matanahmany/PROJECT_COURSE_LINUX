#!/bin/bash
#example command :
#./run_pipeline.sh --plant "rose" --height 50 55 60 65 70 --leaf_count 35 40 45 50 55 --dry_weight 2.0 2.0 2.1 2.1 3.0
# Ensure the script receives arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: ./run_pipeline.sh <python_script_arguments>"
    exit 1
fi

INPUT_DIR="$(pwd)/Ex2_pictures"
OUTPUT_DIR="$(pwd)/Ex3_pictures"


#docker build -t plant2-image -f Dockerfile.python ../

# Step 2: Remove and recreate volume for Python output
echo "🔹 Resetting volume for Python output..."
docker volume rm -f Ex5_2_pictures
docker volume create Ex5_2_pictures

# Step 3: Run the Python container with the provided arguments
echo "🔹 Running Python container..."
docker run --rm -v Ex5_2_pictures:/app plant2-image "$@"

# Step 4: Ensure Ex2_pictures exists
echo "🔹 Organizing Python output..."
mkdir -p Ex2_pictures

# Step 5: Copy generated images from volume to Ex2_pictures
echo "🔹 Copying generated images to Ex2_pictures..."
docker run --rm -v Ex5_2_pictures:/app -v $(pwd)/Ex2_pictures:/host busybox sh -c "cp /app/*.png /host/"


#docker build -t watermark-app -f Dockerfile.java .

# Step 7: Remove and recreate volume for Java output
echo "🔹 Resetting volume for Java output..."
docker volume rm -f Ex5_3_pictures
docker volume create Ex5_3_pictures

# Step 8: Run the Java container (with input directory as argument)
echo "🔹 Running Java container to apply watermarks..."
docker run --rm -v Ex5_2_pictures:/app/Ex5_2_pictures -v Ex5_3_pictures:/app/Ex5_3_pictures watermark-app /app/Ex5_2_pictures

# Step 9: Ensure Ex3_pictures exists
mkdir -p Ex3_pictures

# Step 10: Copy images from volume to Ex3_pictures
echo "🔹 Copying watermarked images to Ex3_pictures..."
docker run --rm -v Ex5_3_pictures:/app -v $(pwd)/Ex3_pictures:/host busybox sh -c "cp /app/*.png /host/"

# Step 11: Clean up Docker resources
echo "🔹 Cleaning up temporary Docker images and containers..."
docker system prune -f

echo "✅ Process completed successfully! Watermarked images are in: $OUTPUT_DIR"
