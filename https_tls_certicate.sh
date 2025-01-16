#!/bin/bash

# Function to print usage
print_usage() {
    echo "Usage: $0 <target>"
    echo "Target can be:"
    echo "  - Hostname (e.g., example.com)"
    echo "  - IP address (e.g., 192.168.1.1)"
    exit 1
}

# Function to calculate days between dates
days_between() {
    local exp_date=$1
    local today=$(date +%s)
    local exp_sec=$(date -d "$exp_date" +%s)
    echo $(( ($exp_sec - $today) / 86400 ))
}

# Check if argument is provided
if [ $# -ne 1 ]; then
    print_usage
fi

HOST=$1
PORT=443

# Function to check certificate
check_cert() {
    local HOST=$1
    local IP
    
    # Get IP if host is not already an IP
    if [[ $HOST =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IP=$HOST
    else
        IP=$(dig +short $HOST | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        if [ -z "$IP" ]; then
            IP=$HOST
        fi
    fi

    # Get certificate chain
    CERT_DATA=$(openssl s_client -connect ${HOST}:${PORT} -servername ${HOST} -showcerts </dev/null 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$CERT_DATA" ]; then
        echo "$HOST,$IP,$PORT,CLOSED,NA,NA,NA,NA,NA"
        return
    fi

    # Initialize variables
    LEAF_CN="UNKNOWN"
    INTERMEDIATE_ISSUER="UNKNOWN"
    ROOT_ISSUER="UNKNOWN"
    ISSUED="UNKNOWN"
    EXPIRES="UNKNOWN"
    
    # Process each certificate in the chain
    cert_count=0
    while read -r line; do
        if [[ "$line" == *"-----BEGIN CERTIFICATE-----"* ]]; then
            cert_data="$line"
            collecting=1
            continue
        fi
        
        if [[ "$line" == *"-----END CERTIFICATE-----"* ]]; then
            cert_data+=$'\n'"$line"
            cert_count=$((cert_count + 1))
            
            # Process based on position in chain
            if [ $cert_count -eq 1 ]; then
                # Leaf certificate
                LEAF_CN=$(echo "$cert_data" | openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p')
                DATES=$(echo "$cert_data" | openssl x509 -noout -dates 2>/dev/null)
                ISSUED=$(echo "$DATES" | grep "notBefore=" | cut -d'=' -f2)
                EXPIRES=$(echo "$DATES" | grep "notAfter=" | cut -d'=' -f2)
            elif [ $cert_count -eq 2 ]; then
                # Intermediate certificate
                INTERMEDIATE_ISSUER=$(echo "$cert_data" | openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p')
            elif [ $cert_count -eq 3 ]; then
                # Root certificate
                ROOT_ISSUER=$(echo "$cert_data" | openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p')
            fi
            collecting=0
            continue
        fi
        
        if [ "$collecting" = "1" ]; then
            cert_data+=$'\n'"$line"
        fi
    done < <(echo "$CERT_DATA" | grep -v "verify" | grep -v "s:" | grep -v "i:" | grep -v "Server certificate" | grep -v "subject=" | grep -v "issuer=")

    # Calculate days until expiration
    DAYS_LEFT=$(days_between "$EXPIRES")

    # Output in CSV format
    echo "$HOST,$IP,$PORT,$LEAF_CN,$INTERMEDIATE_ISSUER,$ROOT_ISSUER,$ISSUED,$EXPIRES,$DAYS_LEFT"
}

# Print CSV header
echo "Hostname,IP,Port,CommonName,IntermediateIssuer,RootIssuer,IssueDate,ExpirationDate,DaysUntilExpiration"

# Check certificate
check_cert "$HOST"
