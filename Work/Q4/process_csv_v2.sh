
#!/bin/bash
#example tp command
#1.    ./process_csv_v2.sh --csv ../Q3/myFile.csv
#2.    ./process_csv_v2.sh -c ../Q3/myFile.csv



# Define paths
PYTHON_SCRIPT="../Q2/plant2.py"
VENV_DIR="$HOME/venv_matan_osher"
DIAGRAMS_DIR="Diagrams"
LOG_FILE="process_log.txt"
Q2_DIR="$(realpath ../Q2)" 
REQ_FILE="$Q2_DIR/requirements.txt"


# Parsing arguments using key-value format
while [[ $# -gt 0 ]]; do
    case "$1" in
        --csv|-c) CSV_FILE="$2"; shift 2;;
        --script|-s) PYTHON_SCRIPT="$2"; shift 2;;
        --requirements|-r) REQ_FILE="$2"; shift 2;;
        --venv|-v) VENV_DIR="$2"; shift 2;;
        --diagrams|-d) DIAGRAMS_DIR="$2"; shift 2;;
        --log|-l) LOG_FILE="$2"; shift 2;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
done


echo "========================================" | tee -a "$LOG_FILE"
echo "Script started at: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure CSV file is provided; if not, search for one near the script
if [ -z "$CSV_FILE" ]; then
    echo "No CSV file provided. Searching for one..." | tee -a "$LOG_FILE"
    CSV_FILE=$(find "$(dirname "$0")" -type f -name "*.csv" | head -n 1)
fi
if [ -n "$CSV_FILE" ]; then
    if [[ ! "$CSV_FILE" =~ \.csv$ ]]; then
        echo "Error: Provided file '$CSV_FILE' is not a CSV file. Exiting." | tee -a "$LOG_FILE"
        exit 1
    fi
    if [ ! -f "$CSV_FILE" ]; then
        echo "Error: The file '$CSV_FILE' does not exist. Exiting." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "No valid CSV file found. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

echo "Using CSV file: $CSV_FILE" | tee -a "$LOG_FILE"

# Validate CSV format (check if the header matches the expected structure)
EXPECTED_HEADER="Plant,Height,Leaf Count,Dry Weight"
ACTUAL_HEADER=$(head -n 1 "$CSV_FILE" | tr -d '\r')
if [ "$ACTUAL_HEADER" != "$EXPECTED_HEADER" ]; then
    echo "Invalid CSV format. Expected: $EXPECTED_HEADER but found: $ACTUAL_HEADER" | tee -a "$LOG_FILE"
    exit 1
fi

# Validate Python script existence
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

# Ensure the virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at $VENV_DIR..." | tee -a "$LOG_FILE"
    python3 -m venv "$VENV_DIR"
    if [ ! -d "$VENV_DIR" ]; then
        echo "Error: Failed to create the virtual environment. Exiting." | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Activate the virtual environment
echo "Activating virtual environment..." | tee -a "$LOG_FILE"
source "$VENV_DIR/bin/activate"
echo "Virtual environment activated." | tee -a "$LOG_FILE"

# Upgrade pip
echo "Upgrading pip..." | tee -a "$LOG_FILE"
pip install --upgrade pip

# Ensure `requirements.txt` exists; if not, generate it dynamically
if [ ! -f "$REQ_FILE" ]; then
    echo "Generating requirements.txt..." | tee -a "$LOG_FILE"
    pip install pipreqs
    python3 -m pipreqs.pipreqs "$Q2_DIR" --force
fi

# Install dependencies in venv based on `requirements.txt`
echo "Installing dependencies from requirements.txt..." | tee -a "$LOG_FILE"
pip install -r "$REQ_FILE" 2>&1 | tee -a "$LOG_FILE"

# Validate installation of dependencies
echo "Validating installed dependencies..." | tee -a "$LOG_FILE"
while read -r package; do
    pkg_name=$(echo "$package" | cut -d'=' -f1)
    if ! pip show "$pkg_name" > /dev/null 2>&1; then
        echo "Error: Dependency $pkg_name is missing after installation!" | tee -a "$LOG_FILE"
        echo "Reinstalling $pkg_name..." | tee -a "$LOG_FILE"
        pip install "$pkg_name"
        if ! pip show "$pkg_name" > /dev/null 2>&1; then
            echo "Error: Failed to install $pkg_name. Exiting." | tee -a "$LOG_FILE"
            exit 1
        fi
    fi
done < "$REQ_FILE"

# Create the main diagrams directory if it doesn't exist
mkdir -p "$DIAGRAMS_DIR"

# Track successful executions
SUCCESS_COUNT=0
TOTAL_COUNT=0

#clean format
clean_input() {
    echo "$1" | tr -d '"' | tr ',' ' ' | sed 's/  */ /g' | sed 's/^ *//g' | sed 's/ *$//g'
}

# Process each row in CSV (skipping header)
{
    read  # Skip header
    while IFS=, read -r plant height leaf_count dry_weight; do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        height=$(clean_input "$height")
        leaf_count=$(clean_input "$leaf_count")
        dry_weight=$(clean_input "$dry_weight")

        # Validate all fields exist
        if [ -z "$plant" ] || [ -z "$height" ] || [ -z "$leaf_count" ] || [ -z "$dry_weight" ]; then
            echo "Skipping plant due to missing values: $plant, $height, $leaf_count, $dry_weight" | tee -a "$LOG_FILE"
            continue
        fi

        # Validate that all values are numbers
        if ! echo "$height" | grep -E '^[0-9., ]+$' > /dev/null || \
           ! echo "$leaf_count" | grep -E '^[0-9., ]+$' > /dev/null || \
           ! echo "$dry_weight" | grep -E '^[0-9., ]+$' > /dev/null; then
            echo "Skipping plant due to invalid numeric values: $plant, $height, $leaf_count, $dry_weight" | tee -a "$LOG_FILE"
            continue
        fi

        # Ensure same number of values in each field
        height_count=$(echo "$height" | wc -w)
        leaf_count_count=$(echo "$leaf_count" | wc -w)
        dry_weight_count=$(echo "$dry_weight" | wc -w)

        if [ "$height_count" -ne "$leaf_count_count" ] || [ "$leaf_count_count" -ne "$dry_weight_count" ]; then
            echo "Skipping plant due to mismatched dimensions: $plant, $height, $leaf_count, $dry_weight" | tee -a "$LOG_FILE"
            continue
        fi

        PLANT_DIR="$DIAGRAMS_DIR/$plant"
        mkdir -p "$PLANT_DIR"

        echo "Processing plant: $plant" | tee -a "$LOG_FILE"

        # Run the Python script and log the output
        python3 "$PYTHON_SCRIPT" --plant "$plant" --height $height --leaf_count $leaf_count --dry_weight $dry_weight | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            # Move only images related to this plant
            mv "${plant}"_*.png "$PLANT_DIR/" 2>/dev/null
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            echo "Processing of $plant completed successfully." | tee -a "$LOG_FILE"
        else
            echo "Error processing plant: $plant" | tee -a "$LOG_FILE"
        fi
    done
} < "$CSV_FILE" 

# Summary report
echo "========================================" | tee -a "$LOG_FILE"
echo "Processing completed: $SUCCESS_COUNT out of $TOTAL_COUNT plants successfully processed." | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Deactivate virtual environment
echo "Deactivating virtual environment..." | tee -a "$LOG_FILE"
deactivate
echo "Virtual environment deactivated." | tee -a "$LOG_FILE"
