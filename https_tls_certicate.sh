#!/bin/bash

# Trap Ctrl+C and cleanup
trap cleanup SIGINT

# Global variable to track if we're exiting
EXITING=0

# Cleanup function
cleanup() {
    echo -e "\nReceived interrupt signal. Cleaning up..."
    EXITING=1
    # Kill any remaining background processes
    jobs -p | xargs -r kill > /dev/null 2>&1
    exit 130
}

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
    
    [ $EXITING -eq 1 ] && return
    
    if [[ $HOST =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IP=$HOST
    else
        IP=$(dig +short $HOST | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        if [ -z "$IP" ]; then
            IP=$HOST
        fi
    fi

    [ $EXITING -eq 1 ] && return

    if ! timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "$HOST,$IP,$PORT,CLOSED,NA,NA,NA,NA"
        return
    fi

    [ $EXITING -eq 1 ] && return

    echo | openssl s_client -connect ${HOST}:${PORT} 2>/dev/null | openssl x509 -noout -text | {
        while IFS= read -r line; do
            [ $EXITING -eq 1 ] && return
            
            case "$line" in
                *"Serial Number:"*) 
                    SERIAL=$(echo $line | sed 's/.*Serial Number: *//; s/[[:space:]]*$//') 
                    ;;
                *"Subject:"*"CN"*) 
                    CN=$(echo $line | sed -n 's/.*CN[[:space:]]*=[[:space:]]*\([^,]*\).*/\1/p')
                    ;;
                *"CN="*) 
                    CN=$(echo $line | sed -n 's/.*CN=\([^,]*\).*/\1/p')
                    ;;
                *"Not Before:"*) 
                    ISSUED=$(echo $line | sed 's/.*Not Before: *//; s/[[:space:]]*$//') 
                    ;;
                *"Not After :"*) 
                    EXPIRES=$(echo $line | sed 's/.*Not After : *//; s/[[:space:]]*$//') 
                    ;;
            esac
        done

        # If CN is still empty, try to get it from subject alternative names
        if [ -z "$CN" ]; then
            CN=$(echo | openssl s_client -connect ${HOST}:${PORT} 2>/dev/null | \
                 openssl x509 -noout -text | \
                 grep -A1 "Subject Alternative Name" | \
                 tail -n1 | sed 's/.*DNS://; s/,.*//; s/[[:space:]]*$//')
        fi

        # If still empty, mark as UNKNOWN
        CN=${CN:-UNKNOWN}
        
        DAYS_LEFT=$(days_between "$EXPIRES")
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
    IP_ADDR=${TARGET%/*}
    PREFIX=${TARGET#*/}
    
    if [ "$PREFIX" -lt 0 ] || [ "$PREFIX" -gt 32 ]; then
        echo "Invalid prefix length. Must be between 0 and 32."
        exit 1
    fi
    
    # Process each IP in the range
    while read -r ip; do
        # Check if we're exiting before processing next IP
        [ $EXITING -eq 1 ] && break
        check_cert "$ip"
    done < <(generate_ip_list "$IP_ADDR" "$PREFIX")
else
    check_cert "$TARGET"
fi

# Final cleanup if we reach the end normally
[ $EXITING -eq 1 ] && cleanup
