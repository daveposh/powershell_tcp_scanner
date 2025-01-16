#!/bin/bash

# Function to print usage
print_usage() {
    echo "Usage: $0 <target>"
    echo "Target can be:"
    echo "  - Hostname (e.g., example.com)"
    echo "  - IP address (e.g., 192.168.1.1)"
    echo "  - IP range in CIDR notation (e.g., 192.168.1.0/24)"
    exit 1
}

# Function to convert IP to decimal
ip2dec() {
    local IFS='.'
    read -r i1 i2 i3 i4 <<< "$1"
    echo $(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
}

# Function to convert decimal to IP
dec2ip() {
    local ip dec=$1
    for e in {3..0}; do
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+=$octet
        [[ $e -gt 0 ]] && ip+=.
    done
    echo $ip
}

# Function to generate IP list from CIDR
generate_ip_list() {
    local ip=$1
    local prefix=$2
    local ip_hex=$(ip2dec "$ip")
    local mask=$((0xffffffff << (32 - prefix)))
    local start=$((ip_hex & mask))
    local end=$((start | ~mask & 0xffffffff))
    
    for ((i=start; i<=end; i++)); do
        dec2ip $i
    done
}

# Function to calculate days between dates
days_between() {
    local exp_date=$1
    local today=$(date +%s)
    local exp_sec=$(date -d "$exp_date" +%s)
    echo $(( ($exp_sec - $today) / 86400 ))
}

# Function to check certificate for a single host
check_cert() {
    local HOST=$1
    local IP
    
    # If input is hostname, resolve IP, otherwise use IP directly
    if [[ $HOST =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IP=$HOST
    else
        IP=$(dig +short $HOST | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        if [ -z "$IP" ]; then
            IP=$HOST
        fi
    fi

    # Test if port 443 is open using timeout to avoid hanging
    if ! timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "$HOST,$IP,$PORT,CLOSED,NA,NA,NA,NA"
        return
    fi

    # Get certificate information using openssl
    echo | openssl s_client -connect ${HOST}:${PORT} 2>/dev/null | openssl x509 -noout -text | {
        while IFS= read -r line; do
            case "$line" in
                *"Serial Number:"*) SERIAL=$(echo $line | sed 's/.*Serial Number: //') ;;
                *"Subject: CN"*) CN=$(echo $line | sed 's/.*CN = //') ;;
                *"Not Before:"*) ISSUED=$(echo $line | sed 's/.*Not Before: //') ;;
                *"Not After :"*) EXPIRES=$(echo $line | sed 's/.*Not After : //') ;;
            esac
        done

        # Calculate days until expiration
        DAYS_LEFT=$(days_between "$EXPIRES")

        # Print results in CSV format
        echo "$HOST,$IP,$PORT,$CN,$SERIAL,$ISSUED,$EXPIRES,$DAYS_LEFT"
    }
}

# Check if argument is provided
if [ $# -ne 1 ]; then
    print_usage
fi

TARGET=$1
PORT=443

# Print CSV header
echo "Hostname,IP,Port,CommonName,SerialNumber,IssueDate,ExpirationDate,DaysUntilExpiration"

# Check if input is CIDR notation
if [[ $TARGET =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    # Split CIDR into IP and prefix
    IP_ADDR=${TARGET%/*}
    PREFIX=${TARGET#*/}
    
    # Validate prefix
    if [ "$PREFIX" -lt 0 ] || [ "$PREFIX" -gt 32 ]; then
        echo "Invalid prefix length. Must be between 0 and 32."
        exit 1
    fi
    
    # Process each IP in the range
    while read -r ip; do
        check_cert "$ip"
    done < <(generate_ip_list "$IP_ADDR" "$PREFIX")
else
    # Single host/IP check
    check_cert "$TARGET"
fi
