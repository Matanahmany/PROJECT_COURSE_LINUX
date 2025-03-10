#!/bin/bash

PROJECT_DIR="$HOME/LINUX_Course_Project"
OUTPUT_FILE="$PROJECT_DIR/Work/Q1/q1_output.txt"

#If not exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

{
    echo "Time : $(date)"                                
    echo "USER DETAILS: $(grep $(whoami) /etc/passwd)"  
    echo "REPO: $PROJECT_DIR"                             
    echo "GithubUrl: $(cd "$PROJECT_DIR" && git remote get-url origin 2>/dev/null || echo "No remote set")" 
    echo "VERSIONID: $(grep '^VERSION_ID' /etc/os-release | cut -d'=' -f2)" 
    echo "---------------------------------------------"
    echo "{ Installing tree package and listing all files in recursive mode }"
} > "$OUTPUT_FILE"

# Install tree
if ! command -v tree &> /dev/null; then
    echo "Installing tree package..."
    sudo apt-get install -y tree
fi

#Add dir recurively
tree "$PROJECT_DIR" 2>&1 | tee -a "$OUTPUT_FILE"

# Add al .sh files under user folder recurively
echo "---------------------------------------------" >> "$OUTPUT_FILE"
echo "List of all my .sh files under user folder recursively" >> "$OUTPUT_FILE"
find ~ -type f -name "*.sh" >> "$OUTPUT_FILE"

echo "Script execution completed successfully!"