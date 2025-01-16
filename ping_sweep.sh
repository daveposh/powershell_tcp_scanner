#!/bin/bash

# Function to get network range from user
get_network_range() {
    echo -e "\nNetwork Range Selection"
    echo "======================"
    
    # Get network address
    read -p "Enter network address (e.g., 192.168.1): " network
    
    echo -e "\nRange Selection"
    echo "==============="
    read -p "Enter start of range (1-254): " start_range
    read -p "Enter end of range (1-254): " end_range
    
    # Validate ranges
    if ! [[ "$start_range" =~ ^[0-9]+$ ]] || ! [[ "$end_range" =~ ^[0-9]+$ ]] || 
       [ "$start_range" -lt 1 ] || [ "$start_range" -gt 254 ] || 
       [ "$end_range" -lt 1 ] || [ "$end_range" -gt 254 ] || 
       [ "$start_range" -gt "$end_range" ]; then
        echo "Invalid range. Using 1-254."
        start_range=1
        end_range=254
    fi
    
    NETWORK=$network
    START_RANGE=$start_range
    END_RANGE=$end_range
}

# Function to get timeout value
get_timeout() {
    echo -e "\nPing Timeout Selection"
    echo "====================="
    echo "1. Quick (500ms)"
    echo "2. Normal (1000ms)"
    echo "3. Thorough (2000ms)"
    echo "4. Custom timeout"
    
    read -p "Select timeout option (1-4): " choice
    
    case $choice in
        1) TIMEOUT=0.5 ;;
        2) TIMEOUT=1 ;;
        3) TIMEOUT=2 ;;
        4)
            read -p "Enter custom timeout in milliseconds (100-5000): " custom_timeout
            if ! [[ "$custom_timeout" =~ ^[0-9]+$ ]] || 
               [ "$custom_timeout" -lt 100 ] || 
               [ "$custom_timeout" -gt 5000 ]; then
                echo "Invalid input. Using 1000ms."
                TIMEOUT=1
            else
                TIMEOUT=$(echo "scale=3; $custom_timeout/1000" | bc)
            fi
            ;;
        *)
            echo "Invalid choice. Using 1000ms."
            TIMEOUT=1
            ;;
    esac
}

# Clear screen
clear
echo "Network Ping Sweep"
echo "=================="

# Get network range
get_network_range

# Get timeout value
get_timeout

# Create output file with timestamp
timestamp=$(date +%Y%m%d_%H%M%S)
output_file="ping_sweep_$timestamp.txt"

echo -e "\nStarting ping sweep..."
echo "Scanning network: $NETWORK.0/24"
echo "Range: $START_RANGE to $END_RANGE"
echo "Timeout: ${TIMEOUT}s"
echo "Results will be saved to: $output_file"
echo

# Add header to file
echo "Network Ping Sweep Results - $(date)" > "$output_file"
echo >> "$output_file"

# Initialize counters
total=$((END_RANGE - START_RANGE + 1))
current=0
responding=0

# Perform ping sweep
for i in $(seq "$START_RANGE" "$END_RANGE"); do
    current=$((current + 1))
    ip="$NETWORK.$i"
    
    # Calculate progress percentage
    progress=$((current * 100 / total))
    printf "Progress: [%-50s] %d%%\r" "$(printf '#%.0s' $(seq $((progress/2))))" "$progress"
    
    # Try ping with timeout
    if ping -c 1 -W "$TIMEOUT" "$ip" >/dev/null 2>&1; then
        responding=$((responding + 1))
        response_time=$(ping -c 1 -W "$TIMEOUT" "$ip" | grep "time=" | cut -d "=" -f4)
        output="$ip Responding - $response_time"
        echo "$output" >> "$output_file"
        echo -e "\e[32m$output\e[0m"  # Green color for responding hosts
    fi
done

# Clear progress line and show completion
echo -e "\n\nScan Complete!"
echo "Total hosts scanned: $total"
echo "Responding hosts: $responding"

# Add summary to file
echo -e "\nScan Complete!" >> "$output_file"
echo "Total hosts scanned: $total" >> "$output_file"
echo "Responding hosts: $responding" >> "$output_file"

echo -e "\nResults have been saved to: $output_file" 