#!/bin/bash

# Port descriptions
declare -A PORT_DESCRIPTIONS=(
    [20]="FTP Data"
    [21]="FTP Control"
    [22]="SSH"
    [23]="Telnet"
    [25]="SMTP"
    [53]="DNS"
    [67]="DHCP Server"
    [68]="DHCP Client"
    [69]="TFTP"
    [80]="HTTP"
    [88]="Kerberos"
    [110]="POP3"
    [123]="NTP"
    [135]="RPC"
    [137]="NetBIOS Name"
    [138]="NetBIOS Datagram"
    [139]="NetBIOS Session"
    [143]="IMAP"
    [161]="SNMP"
    [162]="SNMP Trap"
    [389]="LDAP"
    [443]="HTTPS"
    [445]="SMB"
    [464]="Kerberos Change/Set"
    [465]="SMTP SSL"
    [500]="ISAKMP"
    [514]="Syslog"
    [515]="LPD/LPR"
    [587]="SMTP TLS"
    [631]="IPP"
    [636]="LDAPS"
    [993]="IMAP SSL"
    [995]="POP3 SSL"
    [1433]="MS SQL"
    [1434]="MS SQL Browser"
    [1494]="Citrix ICA"
    [1521]="Oracle"
    [1900]="UPnP"
    [1935]="RTMP"
    [2000]="Cisco SCCP"
    [2049]="NFS"
    [2598]="Citrix CGP"
    [3000]="Dev Server"
    [3268]="Global Catalog"
    [3269]="Global Catalog SSL"
    [3306]="MySQL/MariaDB"
    [3389]="RDP"
    [4200]="Angular Dev"
    [4500]="IPsec NAT-T"
    [5000]="Dev Server"
    [5004]="RTP"
    [5005]="RTP"
    [5432]="PostgreSQL"
    [5722]="DFSR"
    [5985]="WinRM HTTP"
    [5986]="WinRM HTTPS"
    [6379]="Redis"
    [7001]="WebLogic"
    [7002]="WebLogic SSL"
    [8000]="Alt HTTP"
    [8080]="Alt HTTP"
    [8443]="Alt HTTPS"
    [8888]="Alt HTTP"
    [9042]="Cassandra"
    [9043]="WebSphere Admin"
    [9060]="WebSphere Admin"
    [9080]="WebSphere HTTP"
    [9443]="WebSphere HTTPS"
    [27017]="MongoDB"
    [32400]="Plex Media"
    [49152]="Windows RPC"
    [49153]="Windows RPC"
    [49154]="Windows RPC"
    [49155]="Windows RPC"
    [50000]="DB2"
)

# Default settings
TIMEOUT=1
OUTPUT_FILE=""
MINIMAL_OUTPUT=false
ONLY_LISTENING=false

# Function to scan a single port
scan_port() {
    local host=$1
    local port=$2
    local description=${PORT_DESCRIPTIONS[$port]:-"Unknown"}
    
    # Use timeout command with nc (netcat) to test port and suppress its output
    if timeout $TIMEOUT nc -zw1 $host $port 2>/dev/null >/dev/null; then
        if [ "$MINIMAL_OUTPUT" = true ]; then
            echo "$port ($description)"
        else
            echo -e "\e[32m$port ($description)\e[0m"
        fi
        return 0
    else
        if [ "$ONLY_LISTENING" = false ] && [ "$MINIMAL_OUTPUT" = false ]; then
            echo -e "\e[31m$port ($description)\e[0m"
        fi
        return 1
    fi
}

# Function to get scan targets
get_scan_target() {
    echo
    echo "Scan Type Options:"
    echo "=================="
    echo "1. Single host"
    echo "2. Multiple hosts (comma-separated)"
    echo "3. Network range"
    echo "=================="
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            read -p "Enter hostname or IP: " target
            echo "$target"
            ;;
        2)
            read -p "Enter hostnames or IPs (comma-separated): " targets
            echo "$targets" | tr ',' ' '
            ;;
        3)
            read -p "Enter network address (e.g., 192.168.1): " network
            read -p "Enter start of range (1-254): " start
            read -p "Enter end of range (1-254): " end
            
            for i in $(seq $start $end); do
                echo "$network.$i"
            done
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
}

# Function to display selected groups
display_selected_groups() {
    local groups=$1
    echo "----------------------"
    if [ ${#selected_groups[@]} -eq 0 ]; then
        echo "Currently selected: None"
    else
        echo "Currently selected groups:"
        for group in "${selected_groups[@]}"; do
            case $group in
                1)  echo " - Basic Ports" ;;
                2)  echo " - Web Services" ;;
                3)  echo " - Database Ports" ;;
                4)  echo " - Email Ports" ;;
                5)  echo " - File Sharing" ;;
                6)  echo " - Directory Services" ;;
                7)  echo " - Enterprise Apps" ;;
                8)  echo " - Windows Network Services" ;;
                9)  echo " - Network Devices" ;;
                10) echo " - Media Streaming" ;;
                11) echo " - Custom Ports" ;;
                12) echo " - ALL Port Groups" ;;
            esac
        done
    fi
    echo "----------------------"
}

# Function to display port group menu
display_port_menu() {
    echo
    echo "Port Group Selection Menu"
    echo "----------------------"
    echo "Available Port Groups:"
    echo "1.  Basic Ports (80, 443, 22, 3389)"
    echo "2.  Web Services (80, 443, 8080, 8443, etc.)"
    echo "3.  Database Ports (1433, 1521, 3306, etc.)"
    echo "4.  Email Ports (25, 110, 143, etc.)"
    echo "5.  File Sharing (21, 22, 139, 445, etc.)"
    echo "6.  Directory Services (53, 389, 636, etc.)"
    echo "7.  Enterprise Apps (1494, 2598, 5985, etc.)"
    echo "8.  Windows Network Services"
    echo "9.  Network Devices"
    echo "10. Media Streaming"
    echo "11. Custom Ports"
    echo "12. ALL Port Groups"
    echo "0.  Done selecting groups"
    echo "----------------------"
}

# Main script
echo "Network Port Scanner"
echo "------------------"

# Show scan target options menu first
echo
echo "Scan Target Options:"
echo "=================="
echo "1. Single host"
echo "2. Multiple hosts (comma-separated)"
echo "3. Network range"
echo "=================="
read -p "Enter your choice (1-3): " target_choice

# Get targets based on choice
case $target_choice in
    1)
        read -p "Enter hostname or IP: " target
        targets="$target"
        ;;
    2)
        read -p "Enter hostnames or IPs (comma-separated): " targets
        targets=$(echo "$targets" | tr ',' ' ')
        ;;
    3)
        read -p "Enter network address (e.g., 192.168.1): " network
        read -p "Enter start of range (1-254): " start
        read -p "Enter end of range (1-254): " end
        targets=""
        for i in $(seq $start $end); do
            targets="$targets $network.$i"
        done
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Show port group options second
echo
echo "Port Group Selection Menu"
echo "----------------------"
echo "Available Port Groups:"
echo "1.  Basic Ports (80, 443, 22, 3389)"
echo "2.  Web Services (80, 443, 8080, 8443, etc.)"
echo "3.  Database Ports (1433, 1521, 3306, etc.)"
echo "4.  Email Ports (25, 110, 143, etc.)"
echo "5.  File Sharing (21, 22, 139, 445, etc.)"
echo "6.  Directory Services (53, 389, 636, etc.)"
echo "7.  Enterprise Apps (1494, 2598, 5985, etc.)"
echo "8.  Windows Network Services"
echo "9.  Network Devices"
echo "10. Media Streaming"
echo "11. Custom Ports"
echo "12. ALL Port Groups"
echo "0.  Done selecting groups"
echo "----------------------"
echo "Currently selected: None"
echo "----------------------"

# Initialize empty ports string
ports=""
selected_groups=()

while true; do
    display_port_menu
    display_selected_groups "${selected_groups[@]}"
    read -p "Select port group (0-12): " port_choice
    
    if [ "$port_choice" = "0" ]; then
        if [ -z "$ports" ]; then
            echo "Please select at least one port group."
            continue
        fi
        break
    fi

    # Skip if group already selected
    if [[ " ${selected_groups[@]} " =~ " ${port_choice} " ]]; then
        echo "Group already selected. Choose another or press 0 to finish."
        continue
    fi

    new_ports=""
    case $port_choice in
        1)  # Basic
            new_ports="80 443 22 3389"
            ;;
        2)  # Web
            new_ports="80 443 8080 8443 3000 4200 5000 8000 8888"
            ;;
        3)  # Database
            new_ports="1433 1521 3306 5432 27017 6379 9042"
            ;;
        4)  # Email
            new_ports="25 110 143 465 587 993 995"
            ;;
        5)  # File Sharing
            new_ports="21 22 139 445 2049"
            ;;
        6)  # Directory
            new_ports="53 389 636 88 464"
            ;;
        7)  # Enterprise
            new_ports="1494 2598 5985 5986 7001 7002 8443 9043 9060 9080 9443 10443 50000"
            ;;
        8)  # Windows
            new_ports="135 137 138 139 445 389 636 3268 3269 88 464 53 123 5722 49152 49153 49154 49155"
            ;;
        9)  # Network Devices
            new_ports="22 23 161 162 514 830 2000 2001 2002 4786 8080 8443 8888 8291 8728 8729 9440 515 631 9100 9101 9102 500 4500 2601 2602 2603 2604 2605 2606"
            ;;
        10) # Media
            new_ports="554 1935 5004 5005 8554 8000 8090 32469 40000 32400 32410 32412 32413 32414 8096 8920 1900 7359 57621"
            ;;
        11) # Custom
            read -p "Enter custom ports (comma-separated): " custom_ports
            new_ports=$(echo $custom_ports | tr ',' ' ')
            ;;
        12) # ALL
            new_ports="80 443 22 3389 8080 8443 3000 4200 5000 8000 8888 1433 1521 3306 5432 27017 6379 9042 25 110 143 465 587 993 995 21 139 445 2049 53 389 636 88 464 1494 2598 5985 5986 7001 7002 9043 9060 9080 9443 10443 50000 135 137 138 3268 3269 123 5722 49152 49153 49154 49155 161 162 514 830 2000 2001 2002 4786 8291 8728 8729 9440 515 631 9100 9101 9102 500 4500 2601 2602 2603 2604 2605 2606 554 1935 5004 5005 8554 8090 32469 40000 32400 32410 32412 32413 32414 8096 8920 1900 7359 57621"
            selected_groups=("12")
            ports="$new_ports"
            break
            ;;
        *)
            echo "Invalid choice"
            continue
            ;;
    esac

    # Add to selected groups
    selected_groups+=("$port_choice")
    
    # Combine ports, ensuring no duplicates
    if [ -z "$ports" ]; then
        ports="$new_ports"
    else
        # Combine and remove duplicates while maintaining order
        ports="$ports $new_ports"
        ports=$(echo "$ports" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')
    fi

    echo "Selected groups: ${selected_groups[@]}"
    echo "Press 0 when done selecting groups"
done

# Get TCP timeout third
echo
echo "TCP Timeout Options:"
echo "=================="
echo "1. Quick (100 milliseconds)"
echo "2. Normal (500 milliseconds)"
echo "3. Thorough (1000 milliseconds)"
echo "4. Custom timeout"
echo "=================="
read -p "Select timeout option (1-4): " timeout_choice

case $timeout_choice in
    1)
        TIMEOUT=0.1
        ;;
    2)
        TIMEOUT=0.5
        ;;
    3)
        TIMEOUT=1
        ;;
    4)
        read -p "Enter custom timeout in milliseconds (e.g., 750): " custom_timeout
        TIMEOUT=$(echo "scale=3; $custom_timeout/1000" | bc)
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Get scan type fourth
echo
echo "Scan Type Options:"
echo "=================="
echo "1. Full scan (show all ports)"
echo "2. Minimal scan (show only open ports)"
echo "=================="
read -p "Select scan type (1-2): " scan_type

case $scan_type in
    1)
        MINIMAL_OUTPUT=false
        ;;
    2)
        MINIMAL_OUTPUT=true
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Show output options menu last
echo
echo "Results Output Options:"
echo "=================="
echo "1. Display on screen only"
echo "2. Save to file"
echo "3. Both screen and file"
echo "=================="
read -p "Select output option (1-3): " file_choice

case $file_choice in
    2|3)
        # Use current directory for output
        OUTPUT_FILE="./scan_results_$(date +%Y%m%d_%H%M%S).txt"
        
        # Try to create the file
        touch "$OUTPUT_FILE" 2>/dev/null
        
        # Verify file exists and is writable
        if [ ! -f "$OUTPUT_FILE" ] || [ ! -w "$OUTPUT_FILE" ]; then
            echo "Error: Cannot create or write to output file. Check permissions."
            exit 1
        fi
        
        echo "Results will be saved to: $OUTPUT_FILE"
        ;;
esac

# Perform scan
for target in $targets; do
    echo -e "\nScanning $target..."
    open_ports=""
    
    for port in $ports; do
        if result=$(scan_port "$target" "$port"); then
            if [ "$MINIMAL_OUTPUT" = true ]; then
                open_ports="$open_ports $result"
            else
                if [ -n "$OUTPUT_FILE" ]; then
                    echo "$target: $result" >> "$OUTPUT_FILE"
                fi
                echo "$target: $result"
            fi
        else
            if [ "$MINIMAL_OUTPUT" = false ]; then
                if [ -n "$OUTPUT_FILE" ]; then
                    echo "$target: $result" >> "$OUTPUT_FILE"
                fi
                echo "$target: $result"
            fi
        fi
    done

    # Output consolidated results for minimal mode
    if [ "$MINIMAL_OUTPUT" = true ] && [ -n "$open_ports" ]; then
        if [ -n "$OUTPUT_FILE" ]; then
            echo "$target $open_ports" >> "$OUTPUT_FILE"
        fi
        echo "$target $open_ports"
    fi
done

if [ -n "$OUTPUT_FILE" ]; then
    echo -e "\nResults saved to: $OUTPUT_FILE"
fi

echo -e "\nScan complete!" 