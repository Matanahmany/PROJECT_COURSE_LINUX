#!/bin/bash

CSV_FILE=""

# Function to check if a valid CSV file is selected
check_csv_file() {
    if [ -z "$CSV_FILE" ] || [ ! -f "$CSV_FILE" ]; then
        echo "Error: No valid CSV file selected. Select one first (option 2)."
        return 1
    fi
    return 0
}

# Function to clean input by removing extra spaces
clean_input() {
    echo "$1" | sed 's/  */ /g' | xargs
}

while true; do
    echo "=========================="
    echo " Plant Data Manager "
    echo "=========================="
    echo "1. Create a CSV file and display its content"
    echo "2. Select an existing CSV file"
    echo "3. Display the CSV content"
    echo "4. Add a new plant entry"
    echo "5. Run Python script using CSV data"
    echo "6. Update a specific value in a plant's data"
    echo "7. Delete a row (by plant name or index)"
    echo "8. Show plant with the highest average leaf count"
    echo "9. Exit"
    echo "=========================="
    read -p "Please choose an option: " choice

    case $choice in
        1)
            read -p "Enter new CSV file name (must end with .csv): " new_file
            if [[ ! "$new_file" =~ \.csv$ ]]; then
                echo "Error: File must have a .csv extension!"
                continue
            fi
            if [ -f "$new_file" ]; then
                echo "Error: File already exists!"
            else
                echo "Plant,Height,Leaf Count,Dry Weight" > "$new_file"
                CSV_FILE="$new_file"
            fi
            ;;
        2)
            read -p "Enter existing CSV file path: " new_file
            if [[ ! "$new_file" =~ \.csv$ ]]; then
                echo "Error: File must have a .csv extension!"
                continue
            fi
            if [ ! -f "$new_file" ]; then
                echo "Error: File does not exist!"
            else
                CSV_FILE="$new_file"
            fi
            ;;
        3)
            check_csv_file || continue
            cat "$CSV_FILE"
            ;;
        4) 
            check_csv_file || continue

            read -p "Enter plant name: " plant
            if grep -q "^$plant," "$CSV_FILE"; then
                echo "Error: Plant already exists!"
                continue
            fi

            read -p "Enter heights (comma-separated): " height
            read -p "Enter leaf counts (comma-separated): " leaf_count
            read -p "Enter dry weights (comma-separated): " dry_weight

            height=$(clean_input "$height")
            leaf_count=$(clean_input "$leaf_count")
            dry_weight=$(clean_input "$dry_weight")

            if ! echo "$height" | grep -E '^[0-9., ]+$' > /dev/null || \
               ! echo "$leaf_count" | grep -E '^[0-9., ]+$' > /dev/null || \
               ! echo "$dry_weight" | grep -E '^[0-9., ]+$' > /dev/null; then
                echo "Error: All values must be numbers!"
                continue
            fi

            height_count=$(echo "$height" | tr ',' ' ' | wc -w)
            leaf_count_count=$(echo "$leaf_count" | tr ',' ' ' | wc -w)
            dry_weight_count=$(echo "$dry_weight" | tr ',' ' ' | wc -w)

            if [ "$height_count" -ne "$leaf_count_count" ] || [ "$leaf_count_count" -ne "$dry_weight_count" ]; then
                echo "Error: Category dimensions must match!"
                continue
            fi

            echo "$plant,\"$height\",\"$leaf_count\",\"$dry_weight\"" >> "$CSV_FILE"
            ;;
        5)
            check_csv_file || continue

            read -p "Enter plant name to process: " plant_name
            plant_data=$(grep "^$plant_name," "$CSV_FILE")

            if [ -z "$plant_data" ]; then
                echo "Error: Plant not found in the file."
                continue
            fi

            height=$(echo "$plant_data" | cut -d',' -f2 | tr -d '"')
            leaf_count=$(echo "$plant_data" | cut -d',' -f3 | tr -d '"')
            dry_weight=$(echo "$plant_data" | cut -d',' -f4 | tr -d '"')

            python3 ../Q2/plant2.py --plant "$plant_name" --height $height --leaf_count $leaf_count --dry_weight $dry_weight
            ;;
        6)
            check_csv_file || continue

            read -p "Enter the plant name to update: " plant_name
            if ! grep -q "^$plant_name," "$CSV_FILE"; then
                echo "Error: Plant not found!"
                continue
            fi

            echo "Choose category to update:"
            echo "1. Height"
            echo "2. Leaf Count"
            echo "3. Dry Weight"
            read -p "Select a category (1-3): " category_choice

            case $category_choice in
                1) col_num=2 ;;
                2) col_num=3 ;;
                3) col_num=4 ;;
                *) echo "Error: Invalid option"; continue ;;
            esac

            read -p "Enter index inside this category (starting from 1): " data_index
            read -p "Enter new value: " new_value
            new_value=$(clean_input "$new_value")

            if ! [[ "$new_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo "Error: Only numeric values are allowed!"
                continue
            fi

            awk -v name="$plant_name" -v col="$col_num" -v idx="$data_index" -v val="$new_value" '
            BEGIN { FS=OFS="," }
            $1 == name {
                gsub("\"", "", $col)  # Remove existing quotes temporarily
                split($col, values, " ")
                if (idx > 0 && idx <= length(values)) {
                    values[idx] = val  # Update the specific index
                    $col = "\"" values[1]
                    for (i=2; i<=length(values); i++) $col = $col " " values[i]
                    $col = $col "\""  # Add back surrounding quotes
                } else {
                    print "Error: Index out of range!" > "/dev/stderr"
                    exit 1
                }
            } 1' "$CSV_FILE" > temp.csv && mv temp.csv "$CSV_FILE"
            ;;
        7)
            check_csv_file || continue

            echo "Choose deletion method:"
            echo "1. Delete by plant name"
            echo "2. Delete by row index"
            read -p "Choose: " del_choice
            case $del_choice in
                1)  
                    read -p "Enter plant name to delete: " plant_name
                    if ! grep -q "^$plant_name," "$CSV_FILE"; then
                        echo "Error: Plant not found!"
                        continue
                    fi
                    grep -v "^$plant_name," "$CSV_FILE" > temp.csv && mv temp.csv "$CSV_FILE"
                    ;;
                2)  
                    read -p "Enter row index to delete (starting from 2): " row_index
                    if [ "$row_index" -eq 1 ]; then
                        echo "Error: Cannot delete the header row!"
                        continue
                    fi
                    sed -i "${row_index}d" "$CSV_FILE"
                    ;;
                *) echo "Error: Invalid option!" ;;
            esac
            ;;
        8)
            check_csv_file || continue
            awk -F, 'NR>1 {split($3, counts, " "); sum=0; for (i in counts) sum+=counts[i]; avg=sum/length(counts); if (avg > max_avg) {max_avg=avg; best_plant=$1}} END {print "Plant with highest average leaf count:", best_plant}' "$CSV_FILE"
            ;;
        9) exit 0 ;;
        *) echo "Error: Invalid option!" ;;
    esac
done
