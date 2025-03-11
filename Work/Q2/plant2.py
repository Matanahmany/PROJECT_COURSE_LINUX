import argparse
import matplotlib.pyplot as plt
import sys

# Declare parameters from the terminal
parser = argparse.ArgumentParser(description="Generate plant growth plots")
parser.add_argument("--plant", type=str, required=True, help="Name of the plant")
parser.add_argument("--height", type=float, nargs="+", required=True, help="List of height values (cm)")
parser.add_argument("--leaf_count", type=int, nargs="+", required=True, help="List of leaf count values")
parser.add_argument("--dry_weight", type=float, nargs="+", required=True, help="List of dry weight values (g)")
args = parser.parse_args()

# Get the params from the user
plant = args.plant
height_data = args.height
leaf_count_data = args.leaf_count
dry_weight_data = args.dry_weight

#Validation 1: Check if all lists have the same length**
if not (len(height_data) == len(leaf_count_data) == len(dry_weight_data)):
    print("Error: The number of height, leaf count, and dry weight values must be the same!", file=sys.stderr)
    sys.exit(1)

#Validation 2: Ensure all values are non-negative**
if any(h < 0 for h in height_data):
    print("Error: Height values must be non-negative!", file=sys.stderr)
    sys.exit(1)
if any(lc < 0 for lc in leaf_count_data):
    print("Error: Leaf count values must be non-negative!", file=sys.stderr)
    sys.exit(1)
if any(dw < 0 for dw in dry_weight_data):
    print("Error: Dry weight values must be non-negative!", file=sys.stderr)
    sys.exit(1)

# *Validation 3: Ensure plant name is not empty**
if not plant.strip():
    print("Error: Plant name cannot be empty!", file=sys.stderr)
    sys.exit(1)

#If all validations pass, continue with processing
print(f"Plant: {plant}")
print(f"Height data: {height_data} cm")
print(f"Leaf count data: {leaf_count_data}")
print(f"Dry weight data: {dry_weight_data} g")

# Scatter Plot - Height vs Leaf Count
plt.figure(figsize=(10, 6))
plt.scatter(height_data, leaf_count_data, color='b')
plt.title(f'Height vs Leaf Count for {plant}')
plt.xlabel('Height (cm)')
plt.ylabel('Leaf Count')
plt.grid(True)
plt.savefig(f"{plant}_scatter.png")
plt.close()

# Histogram - Distribution of Dry Weight
plt.figure(figsize=(10, 6))
plt.hist(dry_weight_data, bins=5, color='g', edgecolor='black')
plt.title(f'Histogram of Dry Weight for {plant}')
plt.xlabel('Dry Weight (g)')
plt.ylabel('Frequency')
plt.grid(True)
plt.savefig(f"{plant}_histogram.png")
plt.close()

# Line Plot - Plant Height Over Time
weeks = [f'Week {i+1}' for i in range(len(height_data))]
plt.figure(figsize=(10, 6))
plt.plot(weeks, height_data, marker='o', color='r')
plt.title(f'{plant} Height Over Time')
plt.xlabel('Week')
plt.ylabel('Height (cm)')
plt.grid(True)
plt.savefig(f"{plant}_line_plot.png")
plt.close()

# Output confirmation
print(f"Generated plots for {plant}:")
print(f"Scatter plot saved as {plant}_scatter.png")
print(f"Histogram saved as {plant}_histogram.png")
print(f"Line plot saved as {plant}_line_plot.png")
