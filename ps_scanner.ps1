param(
    [switch]$OnlyListening,
    [switch]$MinimalOutput,
    [string]$OutputFile
)

# Move the port descriptions hashtable outside and before any function definitions
$script:portDescriptions = @{
    20 = "FTP Data"
    21 = "FTP Control"
    22 = "SSH"
    23 = "Telnet"
    25 = "SMTP"
    53 = "DNS"
    69 = "TFTP"
    80 = "HTTP"
    88 = "Kerberos"
    110 = "POP3"
    123 = "NTP"
    135 = "RPC"
    137 = "NetBIOS Name"
    138 = "NetBIOS Datagram"
    139 = "NetBIOS Session"
    143 = "IMAP"
    161 = "SNMP"
    162 = "SNMP Trap"
    389 = "LDAP"
    443 = "HTTPS"
    445 = "SMB"
    464 = "Kerberos Password"
    465 = "SMTP SSL"
    500 = "ISAKMP/IKE"
    514 = "Syslog"
    515 = "LPD/LPR Printing"
    587 = "SMTP TLS"
    631 = "IPP Printing"
    636 = "LDAP SSL"
    830 = "NETCONF"
    993 = "IMAP SSL"
    995 = "POP3 SSL"
    1433 = "MS SQL"
    1494 = "Citrix"
    1521 = "Oracle"
    1900 = "DLNA/SSDP"
    1935 = "RTMP"
    2000 = "Cisco SCCP"
    2001 = "Cisco SCCP"
    2002 = "Cisco ACS"
    2049 = "NFS"
    2598 = "Citrix"
    2601 = "Zebra Route 1"
    2602 = "Zebra Route 2"
    2603 = "Zebra Route 3"
    2604 = "Zebra Route 4"
    2605 = "Zebra Route 5"
    2606 = "Zebra/Quagga ISIS"
    3000 = "Dev Server"
    3268 = "Global Catalog"
    3269 = "Global Catalog SSL"
    3306 = "MySQL"
    3389 = "RDP"
    4200 = "Angular Dev"
    4443 = "Firewall Management"
    4500 = "IPSec NAT-T"
    4786 = "Cisco Smart Install"
    5000 = "Dev Server"
    5004 = "RTP Media"
    5005 = "RTP Control"
    5432 = "PostgreSQL"
    5722 = "RPC DFS"
    5985 = "WinRM HTTP"
    5986 = "WinRM HTTPS"
    6001 = "Cisco TMS"
    6007 = "Cisco WSA"
    6379 = "Redis"
    7001 = "WebLogic"
    7002 = "WebLogic SSL"
    7359 = "Emby UDP"
    8000 = "Internet Radio"
    8080 = "HTTP Alt"
    8090 = "DLNA/UPnP"
    8096 = "Jellyfin/Emby HTTP"
    8291 = "MikroTik Winbox"
    8443 = "HTTPS Alt"
    8554 = "RTSP Alt"
    8728 = "MikroTik API"
    8729 = "MikroTik API SSL"
    8888 = "Dev Server"
    8920 = "Jellyfin/Emby HTTPS"
    9042 = "Cassandra"
    9043 = "WebSphere Admin"
    9060 = "WebSphere"
    9080 = "WebSphere HTTP"
    9100 = "Raw Printing"
    9101 = "Raw Printing Alt"
    9102 = "Raw Printing Alt"
    9200 = "Elastic HTTP"
    9300 = "Elastic Transport"
    9440 = "Cisco Meraki"
    9443 = "WebSphere HTTPS"
    10000 = "Network Data"
    27017 = "MongoDB"
    32400 = "Plex Server"
    32410 = "Plex Media UDP"
    32412 = "Plex Media UDP"
    32413 = "Plex Media UDP"
    32414 = "Plex Media UDP"
    32469 = "Plex Media"
    40000 = "Plex Relay"
    49152 = "RPC Dynamic"
    49153 = "RPC Dynamic"
    49154 = "RPC Dynamic"
    49155 = "RPC Dynamic"
    50000 = "SAP"
    57621 = "Spotify Connect"
}

function Get-ScanTarget {
    Write-Host "`nSelect scan type:" -ForegroundColor Cyan
    Write-Host "1. Single host"
    Write-Host "2. Multiple hosts (comma-separated)"
    Write-Host "3. Network range"
    
    $choice = Read-Host "`nEnter your choice (1-3)"
    
    switch ($choice) {
        "1" {
            $target = Read-Host "Enter hostname or IP (e.g., google.com or 192.168.1.1)"
            return @($target)
        }
        "2" {
            $targets = Read-Host "Enter hostnames or IPs (comma-separated)"
            return $targets.Split(',').Trim()
        }
        "3" {
            $network = Read-Host "Enter network address (e.g., 192.168.1)"
            $startRange = Read-Host "Enter start of range (1-254)"
            $endRange = Read-Host "Enter end of range (1-254)"
            
            $targets = @()
            for ($i = [int]$startRange; $i -le [int]$endRange; $i++) {
                $targets += "$network.$i"
            }
            return $targets
        }
        "7" { return @(
            1494,  # Citrix ICA
            2598,  # Citrix CGP
            3389,  # RDP
            5985,  # WinRM HTTP
            5986,  # WinRM HTTPS
            7001,  # WebLogic
            7002,  # WebLogic SSL
            8443,  # HTTPS Alternate
            9043,  # WebSphere Admin
            9060,  # WebSphere
            9080,  # WebSphere HTTP
            9443,  # WebSphere HTTPS
            10443, # SAP
            50000, # SAP
            4120,  # Oracle Enterprise Manager
            4122,  # Oracle Enterprise Manager
            4444,  # WebLogic Admin
            4445,  # WebLogic Admin
            8090,  # Confluence
            8080,  # JIRA
            8085,  # Elastic Search
            9000,  # Elastic Search
            9200,  # Elastic Search HTTP
            9300   # Elastic Search Transport
        ) }
        default {
            Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
            exit
        }
    }
}

function Write-ScanOutput {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = 'White',
        [switch]$NoNewline,
        [switch]$MinimalMode
    )
    
    if ($global:scanOptions.MinimalOutput -and -not $MinimalMode) {
        return
    }
    
    if ($global:scanOptions.OutputToScreen) {
        Write-Host $Message -ForegroundColor $Color -NoNewline:$NoNewline
    }
    
    if ($global:scanOptions.OutputFile) {
        $Message | Out-File -FilePath $global:scanOptions.OutputFile -Append -Encoding UTF8
    }
}

function Get-OutputFilePath {
    param (
        [string]$DefaultFileName
    )
    
    Write-Host "`nFile Output Options:" -ForegroundColor Cyan
    Write-Host "1. Use default path"
    Write-Host "2. Specify custom path"
    Write-Host "3. Specify custom filename (in script directory)"
    
    # Get script directory for default location
    $scriptDir = $PSScriptRoot
    if (!$scriptDir) {
        $scriptDir = Split-Path -Parent -Path $MyInvocation.ScriptName
    }
    if (!$scriptDir) {
        $scriptDir = Get-Location
    }
    
    $defaultPath = Join-Path -Path $scriptDir -ChildPath $DefaultFileName
    
    Write-Host "`nDefault path:" -NoNewline
    Write-Host " $defaultPath" -ForegroundColor Yellow
    
    $pathChoice = Read-Host "`nSelect option (1-3)"
    
    switch ($pathChoice) {
        "1" { 
            return $defaultPath
        }
        "2" {
            $customPath = Read-Host "Enter complete file path (including filename)"
            if ([string]::IsNullOrWhiteSpace($customPath)) {
                Write-Host "No path specified, using default" -ForegroundColor Yellow
                return $defaultPath
            }
            
            try {
                $directory = Split-Path -Parent -Path $customPath
                if (!(Test-Path -Path $directory)) {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    Write-Host "Created directory: $directory" -ForegroundColor Green
                }
                return $customPath
            }
            catch {
                Write-Host "Error with custom path, using default" -ForegroundColor Red
                return $defaultPath
            }
        }
        "3" {
            $customFileName = Read-Host "Enter filename"
            if ([string]::IsNullOrWhiteSpace($customFileName)) {
                Write-Host "No filename specified, using default" -ForegroundColor Yellow
                return $defaultPath
            }
            
            # Add .txt extension if not specified
            if ([System.IO.Path]::GetExtension($customFileName) -eq "") {
                $customFileName = "$customFileName.txt"
            }
            
            return Join-Path -Path $scriptDir -ChildPath $customFileName
        }
        default {
            Write-Host "Invalid choice, using default path" -ForegroundColor Yellow
            return $defaultPath
        }
    }
}

function Get-TimeoutValue {
    param (
        [int]$CurrentTimeout = 250
    )
    
    Write-Host "`nTCP Timeout Settings:" -ForegroundColor Cyan
    Write-Host "Current timeout: $CurrentTimeout ms"
    Write-Host "1. Use default (250ms)"
    Write-Host "2. Quick scan (100ms)"
    Write-Host "3. Thorough scan (500ms)"
    Write-Host "4. Enter custom value"
    Write-Host "5. Keep current setting"
    
    $timeoutChoice = Read-Host "`nSelect option (1-5)"
    
    switch ($timeoutChoice) {
        "1" { return 250 }
        "2" { return 100 }
        "3" { return 500 }
        "4" {
            Write-Host "`nEnter custom timeout value in milliseconds (50-2000)"
            Write-Host "Recommended ranges:" -ForegroundColor Yellow
            Write-Host "  50-150ms:   Very quick, local network only"
            Write-Host "  200-350ms:  Standard, good for most networks"
            Write-Host "  400-750ms:  Thorough, good for slower connections"
            Write-Host "  1000ms+:    Very thorough, may be slow"
            
            $customTimeout = Read-Host "Timeout (ms)"
            try {
                $timeout = [int]$customTimeout
                if ($timeout -lt 50) {
                    Write-Host "Value too low, setting to minimum (50ms)" -ForegroundColor Yellow
                    return 50
                }
                elseif ($timeout -gt 2000) {
                    Write-Host "Value too high, setting to maximum (2000ms)" -ForegroundColor Yellow
                    return 2000
                }
                return $timeout
            }
            catch {
                Write-Host "Invalid value, using default (250ms)" -ForegroundColor Red
                return 250
            }
        }
        "5" { return $CurrentTimeout }
        default {
            Write-Host "Invalid choice, using default (250ms)" -ForegroundColor Yellow
            return 250
        }
    }
}

function Get-ScanOptions {
    $global:scanOptions = @{
        MinimalOutput = $false
        OutputFile = ""
        OnlyListening = $false
        OutputToScreen = $true
        TimeoutMS = 250
    }

    Write-Host "`nScan Options:" -ForegroundColor Cyan
    Write-Host "1. Normal output (detailed)"
    Write-Host "2. Minimal output (IP:ports only)"
    $outputChoice = Read-Host "`nSelect output type (1-2)"
    
    $global:scanOptions.MinimalOutput = $outputChoice -eq "2"
    
    Write-Host "`nOutput Options:" -ForegroundColor Cyan
    Write-Host "1. Display on screen only"
    Write-Host "2. Save to file only"
    Write-Host "3. Both screen and file"
    $fileChoice = Read-Host "`nSelect output option (1-3)"
    
    switch ($fileChoice) {
        "1" { 
            $global:scanOptions.OutputToScreen = $true
            $global:scanOptions.OutputFile = ""
        }
        "2" { 
            $global:scanOptions.OutputToScreen = $false
            $defaultFileName = "scan_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $global:scanOptions.OutputFile = Get-OutputFilePath -DefaultFileName $defaultFileName
        }
        "3" {
            $global:scanOptions.OutputToScreen = $true
            $defaultFileName = "scan_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $global:scanOptions.OutputFile = Get-OutputFilePath -DefaultFileName $defaultFileName
        }
    }
    
    if ($global:scanOptions.OutputFile) {
        Write-Host "`nResults will be saved to:" -NoNewline
        Write-Host " $($global:scanOptions.OutputFile)" -ForegroundColor Green
    }
    
    Write-Host "`nListening Hosts:" -ForegroundColor Cyan
    Write-Host "1. Show all results"
    Write-Host "2. Show only listening hosts"
    $listenChoice = Read-Host "`nSelect option (1-2)"
    
    $global:scanOptions.OnlyListening = $listenChoice -eq "2"

    # Get timeout setting using new function
    $global:scanOptions.TimeoutMS = Get-TimeoutValue -CurrentTimeout $global:scanOptions.TimeoutMS
    
    Write-Host "`nSelected timeout:" -NoNewline
    Write-Host " $($global:scanOptions.TimeoutMS)ms" -ForegroundColor Green
}

function Test-HostConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        
        [Parameter(Mandatory=$false)]
        [int[]]$Ports = @(80, 443, 22, 3389),
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMilliseconds = 250
    )

    $hasOpenPorts = $false
    $openPorts = @()
    $results = @()

    # Test if host responds to ping first
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send($HostName, 1000)
        if ($result.Status -ne 'Success') {
            if (-not $global:scanOptions.MinimalOutput) {
                Write-Host "Host $HostName is not responding to ping" -ForegroundColor Yellow
            }
            return
        }
    }
    catch {
        if (-not $global:scanOptions.MinimalOutput) {
            Write-Host "Error pinging $HostName" -ForegroundColor Red
        }
        return
    }

    # Always show scanning message regardless of minimal output
    Write-Host "`nScanning $HostName..." -ForegroundColor Cyan
    
    foreach ($Port in $Ports) {
        $portDesc = if ($script:portDescriptions.ContainsKey($Port)) { 
            " ($($script:portDescriptions[$Port]))" 
        } else { 
            "" 
        }
        
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne($global:scanOptions.TimeoutMS, $false)
            
            if ($wait) {
                try {
                    $tcpClient.EndConnect($connect)
                    $hasOpenPorts = $true
                    $openPorts += $Port
                    
                    if ($global:scanOptions.MinimalOutput) {
                        $portString = if ($script:portDescriptions.ContainsKey($Port)) {
                            "$Port ($($script:portDescriptions[$Port]))"
                        } else {
                            "$Port"
                        }
                        $results += $portString
                    } else {
                        Write-Host "Port $Port$portDesc is open" -ForegroundColor Green
                        if ($global:scanOptions.OutputFile) {
                            "Port $Port$portDesc is open" | Out-File -FilePath $global:scanOptions.OutputFile -Append
                        }
                    }
                } catch {
                    if (-not $global:scanOptions.OnlyListening -and -not $global:scanOptions.MinimalOutput) {
                        Write-Host "Port $Port$portDesc is closed" -ForegroundColor Red
                    }
                }
            } else {
                if (-not $global:scanOptions.OnlyListening -and -not $global:scanOptions.MinimalOutput) {
                    Write-Host "Port $Port$portDesc timed out" -ForegroundColor Yellow
                }
            }
        }
        catch {
            if (-not $global:scanOptions.OnlyListening -and -not $global:scanOptions.MinimalOutput) {
                Write-Host "Error scanning port $Port$portDesc" -ForegroundColor Red
            }
        }
        finally {
            if ($null -ne $tcpClient) {
                $tcpClient.Close()
                $tcpClient.Dispose()
            }
        }
        
        # Add a small delay between port scans
        Start-Sleep -Milliseconds 20
    }

    # Output summary for hosts with open ports
    if ($hasOpenPorts) {
        if ($global:scanOptions.MinimalOutput) {
            $output = "$HostName : $($results -join ', ')"
            Write-Host $output -ForegroundColor Green
            if ($global:scanOptions.OutputFile) {
                $output | Out-File -FilePath $global:scanOptions.OutputFile -Append
            }
        }
    }
}

function Get-PortGroupSelection {
    $selectedPorts = @()
    $continue = $true
    
    while ($continue) {
        Clear-Host
        Write-Host "Port Group Selection Menu" -ForegroundColor Cyan
        Write-Host "----------------------" -ForegroundColor Cyan
        Write-Host "Selected Groups: " -NoNewline
        if ($selectedPorts.Count -eq 0) {
            Write-Host "None" -ForegroundColor Yellow
        } else {
            Write-Host ($selectedPorts -join ", ") -ForegroundColor Green
        }
        Write-Host "`nAvailable Port Groups:"
        Write-Host "1.  Basic Ports (80, 443, 22, 3389)"
        Write-Host "2.  Web Services (80, 443, 8080, 8443, etc.)"
        Write-Host "3.  Database Ports (1433, 1521, 3306, etc.)"
        Write-Host "4.  Email Ports (25, 110, 143, etc.)"
        Write-Host "5.  File Sharing (21, 22, 139, 445, etc.)"
        Write-Host "6.  Directory Services (53, 389, 636, etc.)"
        Write-Host "7.  Enterprise Apps (1494, 2598, 5985, etc.)"
        Write-Host "8.  Windows Network Services"
        Write-Host "9.  Network Devices (Switches, APs, Firewalls, Printers)"
        Write-Host "10. Media Streaming (Plex, Emby, DLNA, etc.)"
        Write-Host "11. Custom Ports"
        Write-Host "12. ALL Port Groups"
        Write-Host "13. Done - Start Scan"
        Write-Host "14. Clear Selections"
        Write-Host "Q.  Quit"
        
        $choice = Read-Host "`nEnter your choice"
        
        switch ($choice) {
            "1" { $selectedPorts += "Basic" }
            "2" { $selectedPorts += "Web" }
            "3" { $selectedPorts += "Database" }
            "4" { $selectedPorts += "Email" }
            "5" { $selectedPorts += "FileSharing" }
            "6" { $selectedPorts += "Directory" }
            "7" { $selectedPorts += "Enterprise" }
            "8" { $selectedPorts += "Windows" }
            "9" { $selectedPorts += "Network" }
            "10" { $selectedPorts += "Media" }
            "11" { 
                $customPorts = Read-Host "Enter custom ports (comma-separated)"
                $selectedPorts += "Custom:$customPorts"
            }
            "12" { 
                $selectedPorts = @("ALL")
                $continue = $false
            }
            "13" { 
                if ($selectedPorts.Count -eq 0) {
                    Write-Host "`nNo ports selected! Please select at least one group." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                } else {
                    $continue = $false
                }
            }
            "14" { $selectedPorts = @() }
            "Q" { exit }
            default {
                Write-Host "`nInvalid selection!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        
        $selectedPorts = $selectedPorts | Select-Object -Unique
    }
    
    return $selectedPorts
}

function Get-PortsFromGroups {
    param (
        [array]$Groups
    )
    
    $allPorts = [System.Collections.ArrayList]@()
    
    foreach ($group in $Groups) {
        if ($group -eq "ALL") {
            return Get-AllPorts
        }
        elseif ($group -like "Custom:*") {
            $customPorts = $group.Split(':')[1]
            $customPorts.Split(',').Trim() | ForEach-Object { 
                [void]$allPorts.Add([int]$_) 
            }
        }
        else {
            switch ($group) {
                "Basic" { 
                    [void]$allPorts.AddRange(@(80, 443, 22, 3389))
                }
                "Web" { 
                    [void]$allPorts.AddRange(@(80, 443, 8080, 8443, 3000, 4200, 5000, 8000, 8888))
                }
                "Database" { 
                    [void]$allPorts.AddRange(@(1433, 1521, 3306, 5432, 27017, 6379, 9042))
                }
                "Email" { 
                    [void]$allPorts.AddRange(@(25, 110, 143, 465, 587, 993, 995))
                }
                "FileSharing" { 
                    [void]$allPorts.AddRange(@(21, 22, 139, 445, 2049))
                }
                "Directory" { 
                    [void]$allPorts.AddRange(@(53, 389, 636, 88, 464))
                }
                "Enterprise" { 
                    [void]$allPorts.AddRange(@(1494, 2598, 5985, 5986, 7001, 7002, 8443, 9043, 9060, 9080, 9443, 10443, 50000))
                }
                "Windows" { 
                    [void]$allPorts.AddRange(@(135, 137, 138, 139, 445, 389, 636, 3268, 3269, 88, 464, 53, 123, 5722, 49152, 49153, 49154, 49155))
                }
                "Network" { 
                    [void]$allPorts.AddRange(@(
                        22, 23, 161, 162, 514, 830,  # Basic Management
                        2000, 2001, 2002,            # Cisco Voice
                        4786,                        # Cisco Smart Install
                        8080, 8443, 8888,           # Web Management
                        8291, 8728, 8729,           # MikroTik
                        9440,                        # Meraki
                        515, 631, 9100, 9101, 9102, # Printers
                        500, 4500,                  # VPN/IPSec
                        2601, 2602, 2603, 2604, 2605, 2606  # Routing Protocols
                    ))
                }
                "Media" { 
                    [void]$allPorts.AddRange(@(
                        554,    # RTSP
                        1935,   # RTMP
                        5004,   # RTP Media
                        5005,   # RTP Control
                        8554,   # RTSP Alt
                        8000,   # Internet Radio
                        8090,   # DLNA/UPnP
                        32469,  # Plex Media
                        40000,  # Plex Relay
                        32400,  # Plex Server
                        32410,  # Plex Media UDP
                        32412,  # Plex Media UDP
                        32413,  # Plex Media UDP
                        32414,  # Plex Media UDP
                        8096,   # Jellyfin/Emby HTTP
                        8920,   # Jellyfin/Emby HTTPS
                        1900,   # DLNA/SSDP
                        7359,   # Emby UDP
                        57621   # Spotify Connect
                    ))
                }
            }
        }
    }
    
    return $allPorts | Select-Object -Unique | Sort-Object
}

function Get-AllPorts {
    return Get-PortsFromGroups @(
        "Basic", "Web", "Database", "Email", "FileSharing",
        "Directory", "Enterprise", "Windows", "Network"
    )
}

# Main script execution
Clear-Host
Write-Host "PowerShell Network Scanner" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

# Get scan options first
Get-ScanOptions

# Initialize output file if specified
if ($global:scanOptions.OutputFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Set-Content -Path $global:scanOptions.OutputFile -Value "PowerShell Network Scanner Results - $timestamp`n" -Encoding UTF8
}

# Get targets from user
$targets = Get-ScanTarget

# Get port groups from user
$selectedGroups = Get-PortGroupSelection
$ports = Get-PortsFromGroups -Groups $selectedGroups

if (-not $global:scanOptions.MinimalOutput) {
    Write-ScanOutput "`nSelected Ports: $($ports.Count) ports to scan" -Color Cyan
    $showPorts = Read-Host "Show all selected ports? (y/n)"
    if ($showPorts -eq 'y') {
        Write-ScanOutput ($ports -join ", ") -Color Yellow
    }
}

# Scan each target
foreach ($target in $targets) {
    Test-HostConnection -HostName $target.Trim() -Ports $ports
}

if ($global:scanOptions.OutputFile -and -not $global:scanOptions.MinimalOutput) {
    Write-ScanOutput "`nResults have been saved to: $($global:scanOptions.OutputFile)" -Color Green
}

if (-not $global:scanOptions.MinimalOutput) {
    Write-ScanOutput "`nScan complete!" -Color Green
}