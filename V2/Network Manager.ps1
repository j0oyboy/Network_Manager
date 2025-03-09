chcp 65001 > $null
# Change Window Size
[console]::SetWindowSize(120, 31)

# Change the Windows Name
$host.UI.RawUI.WindowTitle = "Advanced Network Tool"

#Functions
function Center-text ($text){
    $width = [console]::WindowWidth
    $padLef = [math]::Max(0,($width - $text.Length)) / 2
    return (' ' * $padLef) + $text
}

<# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n This script requires administrator privileges." -ForegroundColor Red
    Write-Host "`n [-] Please run PowerShell as administrator and try again..." -ForegroundColor Red
    Read-Host "`n Press Enter to exit"
    exit
}#>

# Global variables
$global:selectedInterface = $null
$global:savedProfiles = @{}
$global:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$global:profilesPath = Join-Path -Path $global:scriptPath -ChildPath "network_profiles.xml"

# Load saved profiles if they exist
if (Test-Path $global:profilesPath) {
    try {
        $global:savedProfiles = Import-Clixml -Path $global:profilesPath
        Write-Host " Loaded saved network profiles." -ForegroundColor Cyan
    } catch {
        Write-Host " Error loading profiles: $_" -ForegroundColor Red
    }
}
$Banner = @(
    " ",
    " ",
    "███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗    ████████╗ ██████╗  ██████╗ ██╗      ",
    "████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║      ",
    "██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝        ██║   ██║   ██║██║   ██║██║      ",
    "██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗        ██║   ██║   ██║██║   ██║██║      ",
    "██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗       ██║   ╚██████╔╝╚██████╔╝███████╗ ",
    "╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝ ",                                                                                                
    "                                                                                             ADVANCED EDITION",
    "                                                                                                  by Souhaib ",
    " "
)
$menu = @(
    " ",
    "╔═══════════════════════════════════════════════════╗"
    "║  1. View Network Adapters                         ║",
    "║  2. Get Interface Information                     ║",
    "║  3. Configure IP Address (Static/DHCP)            ║",
    "║  4. Network Diagnostics & Troubleshooting         ║",
    "║  5. Network Profiles (Save/Load Configurations)   ║",
    "║  6. Wi-Fi Management                              ║",
    "║  7. Firewall Management                           ║",
    "║  8. Network Monitoring                            ║",
    "║  9. Change Selected Interface                     ║",
    "║ 10. Exit the script                               ║",
    "╚═══════════════════════════════════════════════════╝",
    " "
)
$interfaceMenu = @(
    " ",
    "╔═══════════════════════════════╗",
    "║ 1. Interface Description      ║",
    "║ 2. MAC Address                ║",
    "║ 3. Interface Status           ║",
    "║ 4. Link Speed                 ║",
    "║ 5. IP Configuration           ║",
    "║ 6. Advanced Properties        ║",
    "║ 0. Return to Main Menu        ║",
    "╚═══════════════════════════════╝"
)
$ipConfigMenu = @(
    " ",
    "╔════════════════════════════════════╗",
    "║ 1. Configure Static IPv4           ║",
    "║ 2. Configure Static IPv6           ║",
    "║ 3. Configure DHCP                  ║",
    "║ 4. Add Additional IP Address       ║",
    "║ 5. Configure DNS Servers           ║",
    "║ 6. View Current Configuration      ║",
    "║ 0. Return To the Main Menu         ║",
    "╚════════════════════════════════════╝"
)

# Diagnostic menu
$diagnosticsMenu = @(
    " ",
    "╔═══════════════════════════════════════╗",
    "║ 1. Ping Test                          ║",
    "║ 2. Trace Route                        ║",
    "║ 3. DNS Lookup                         ║",
    "║ 4. Run Network Speed Test             ║",
    "║ 5. Check for Network Connectivity     ║",
    "║ 6. Test Port Connectivity             ║",
    "║ 7. View Connection Statistics         ║",
    "║ 0. Return to Main Menu                ║",
    "╚═══════════════════════════════════════╝"
)

# Network Profiles menu
$profilesMenu = @(
    " ",
    "╔════════════════════════════════════════╗",
    "║ 1. Save Current Configuration          ║",
    "║ 2. Load Saved Profile                  ║",
    "║ 3. Delete Saved Profile                ║",
    "║ 4. View All Saved Profiles             ║",
    "║ 0. Return to Main Menu                 ║",
    "╚════════════════════════════════════════╝"
)

# Wi-Fi Management menu
$wifiMenu = @(
    " ",
    "╔════════════════════════════════════════╗",
    "║ 1. View Available Networks             ║",
    "║ 2. Connect to Wi-Fi Network            ║",
    "║ 3. Disconnect from Wi-Fi               ║",
    "║ 4. Manage Saved Networks               ║",
    "║ 5. View Wi-Fi Signal Strength          ║",
    "║ 6. Create Wi-Fi Hotspot                ║",
    "║ 0. Return to Main Menu                 ║",
    "╚════════════════════════════════════════╝"
)

# Firewall Management menu
$firewallMenu = @(
    " ",
    "╔════════════════════════════════════════╗",
    "║ 1. View Firewall Status                ║",
    "║ 2. Enable/Disable Firewall             ║",
    "║ 3. Add Firewall Rule                   ║",
    "║ 4. Remove Firewall Rule                ║",
    "║ 5. View Active Firewall Rules          ║",
    "║ 0. Return to Main Menu                 ║",
    "╚════════════════════════════════════════╝"
)

# Network Monitoring menu
$monitoringMenu = @(
    " ",
    "╔════════════════════════════════════════╗",
    "║ 1. Monitor Network Traffic             ║",
    "║ 2. View Active Connections             ║",
    "║ 3. View Bandwidth Usage                ║",
    "║ 4. Network Performance Statistics      ║",
    "║ 5. Start Continuous Monitoring         ║",
    "║ 0. Return to Main Menu                 ║",
    "╚════════════════════════════════════════╝"
)

function Show-Banner {
    Clear-Host
    foreach ($line in $Banner) {
        Write-Host (center-text $line) -ForegroundColor Red
    }
    
    # Display current selected interface if one is selected
    if ($global:selectedInterface) {
        $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $global:selectedInterface }
        $status = if ($interface.Status -eq "Up") { "Connected" } else { "Disconnected" }
        Write-Host ""
        Write-Host (Center-text " Selected Interface: $($interface.Name) - $status") -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host (Center-text " No network interface selected. Please select one to continue.") -ForegroundColor Yellow
    }
}

function Show-Menu {
    foreach ($line in $menu) {
        Write-Host ( Center-text $line)
    }

    Write-Host ""
    $choice = Read-Host " ♥ Please enter your choice"
    return $choice
}

function Select-NetworkInterface {
    Show-Banner
    Write-Host ""
    Write-Host "`n Available Network Interfaces:" -ForegroundColor Green
    Write-Host " -----------------------------" -ForegroundColor Green
    
    $interfaces = Get-NetAdapter | Select-Object -Property Name, InterfaceDescription, Status, LinkSpeed, MacAddress
    
    $count = 1
    $interfaceList = @{}
    
    foreach ($interface in $interfaces) {
        Write-Host " $count. $($interface.Name) - $($interface.InterfaceDescription) - $($interface.Status)" -ForegroundColor Cyan
        $interfaceList[$count] = $interface.InterfaceDescription
        $count++
    }
    
    Write-Host " 0. Return to Main Menu" -ForegroundColor Cyan
    Write-Host ""
    $selection = Read-Host "`n ► Select a network interface"
    
    if ($selection -eq "0") {
        return
    }
    
    if ($selection -match '^\d+$' -and $interfaceList.ContainsKey([int]$selection)) {
        $global:selectedInterface = $interfaceList[[int]$selection]
        Write-Host "`n Selected interface: $global:selectedInterface" -ForegroundColor Green
        Start-Sleep -Seconds 1
    } else {
        Write-Host "`n [-] Invalid selection. Please try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Select-NetworkInterface
    }
}

function Get-InterfaceInfo {
    if (-not $global:selectedInterface) {
        Write-Host "`n [-] No interface selected. Please select an interface first." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Select-NetworkInterface
        return
    }
    
    Show-Banner
    foreach ($line in $interfaceMenu) {
        Write-Host ( Center-text $line )
    }
    
    $choice = Read-Host "`n ♀ Please enter your choice"
    
    $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $global:selectedInterface }
    
    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "`n Interface Description:" -ForegroundColor Green
            Write-Host " ---------------------" -ForegroundColor Green
            Write-Host " Name: $($interface.Name)" -ForegroundColor Cyan
            Write-Host " Description: $($interface.InterfaceDescription)" -ForegroundColor Cyan
            Write-Host " Interface Index: $($interface.ifIndex)" -ForegroundColor Cyan
            Write-Host " Admin Status: $($interface.AdminStatus)" -ForegroundColor Cyan
            Write-Host " Media Type: $($interface.MediaType)" -ForegroundColor Cyan
            Write-Host " Physical Media Type: $($interface.PhysicalMediaType)" -ForegroundColor Cyan
            Write-Host
            Read-Host "`n Press Enter to continue"
            Get-InterfaceInfo
        }
        "2" {
            Clear-Host
            Write-Host "`n MAC Address Information:" -ForegroundColor Green
            Write-Host " -----------------------" -ForegroundColor Green
            Write-Host " MAC Address: $($interface.MacAddress)" -ForegroundColor Cyan
            Write-Host " Permanent MAC Address: $($interface.PermanentMacAddress)" -ForegroundColor Cyan
            Write-Host
            Read-Host "`n Press Enter to continue"
            Get-InterfaceInfo
        }
        "3" {
            Clear-Host
            Write-Host "`n Interface Status:" -ForegroundColor Green
            Write-Host " ----------------" -ForegroundColor Green
            Write-Host " Status: $($interface.Status)" -ForegroundColor Cyan
            Write-Host " Connection Status: $($interface.MediaConnectionState)" -ForegroundColor Cyan
            
            if ($interface.Status -eq "Up") {
                Write-Host " Interface is active and connected." -ForegroundColor Green
            } else {
                Write-Host "[-] Interface is not connected." -ForegroundColor Yellow
            }
            
            Write-Host
            Read-Host "`n Press Enter to continue"
            Get-InterfaceInfo
        }
        "4" {
            Clear-Host
            Write-Host "`n Link Speed Information:" -ForegroundColor Green
            Write-Host " -----------------------" -ForegroundColor Green
            Write-Host " Current Link Speed: $($interface.LinkSpeed)" -ForegroundColor Cyan
            
            # Get supported link speeds if available
            try {
                $linkCapabilities = Get-NetAdapterAdvancedProperty -InterfaceDescription $global:selectedInterface | Where-Object { $_.RegistryKeyword -like "*Speed*" -or $_.RegistryKeyword -like "*Duplex*" }
                
                if ($linkCapabilities) {
                    Write-Host "`n Supported Link Capabilities:" -ForegroundColor Green
                    foreach ($capability in $linkCapabilities) {
                        Write-Host " $($capability.DisplayName): $($capability.DisplayValue)" -ForegroundColor Cyan
                    }
                }
            } catch {
                Write-Host " Could not retrieve advanced link capabilities." -ForegroundColor Yellow
            }
            
            Write-Host
            Read-Host "`n Press Enter to continue"
            Get-InterfaceInfo
        }
        "5" {
            Clear-Host
            Write-Host "`n IP Configuration:" -ForegroundColor Green
            Write-Host " ----------------" -ForegroundColor Green
            
            $ipConfig = Get-NetIPConfiguration -InterfaceIndex $interface.ifIndex
            $ipAddresses = Get-NetIPAddress -InterfaceIndex $interface.ifIndex
            
            # Show IPv4 addresses
            $ipv4 = $ipAddresses | Where-Object { $_.AddressFamily -eq "IPv4" }
            if ($ipv4) {
                Write-Host "`n IPv4 Addresses:" -ForegroundColor Yellow
                Write-Host " --------------" -ForegroundColor Yellow
                foreach ($ip in $ipv4) {
                    Write-Host "  Address: $($ip.IPAddress)" -ForegroundColor Cyan
                    Write-Host "  Prefix Length: $($ip.PrefixLength)" -ForegroundColor Cyan
                    Write-Host "  Type: $($ip.Type)" -ForegroundColor Cyan
                    Write-Host ""
                }
            } else {
                Write-Host " No IPv4 addresses configured." -ForegroundColor Yellow
            }
            
            # Show IPv6 addresses
            $ipv6 = $ipAddresses | Where-Object { $_.AddressFamily -eq "IPv6" }
            if ($ipv6) {
                Write-Host " IPv6 Addresses:" -ForegroundColor Yellow
                Write-Host " --------------" -ForegroundColor Yellow
                foreach ($ip in $ipv6) {
                    Write-Host "  Address: $($ip.IPAddress)" -ForegroundColor Cyan
                    Write-Host "  Prefix Length: $($ip.PrefixLength)" -ForegroundColor Cyan
                    Write-Host "  Type: $($ip.Type)" -ForegroundColor Cyan
                    Write-Host ""
                }
            } else {
                Write-Host " [-] No IPv6 addresses configured." -ForegroundColor Yellow
            }
            
            # Show gateway
            if ($ipConfig.IPv4DefaultGateway) {
                Write-Host " Default Gateway: $($ipConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor Yellow
            } else {
                Write-Host " No IPv4 default gateway configured." -ForegroundColor Yellow
            }
            
            # Show DNS servers
            if ($ipConfig.DNSServer) {
                Write-Host ""
                Write-Host " DNS Servers:" -ForegroundColor Yellow
                foreach ($dns in $ipConfig.DNSServer) {
                    Write-Host "  $($dns.ServerAddresses)" -ForegroundColor Cyan
                }
            } else {
                Write-Host " [-] No DNS servers configured." -ForegroundColor Yellow
            }
            
            Write-Host
            Read-Host "`n Press Enter to continue"
            Get-InterfaceInfo
        }
        "6" {
            Clear-Host
            Write-Host "`n Advanced Properties:" -ForegroundColor Green
            Write-Host " -------------------" -ForegroundColor Green
            
            try {
                $advProperties = Get-NetAdapterAdvancedProperty -InterfaceDescription $global:selectedInterface
                
                if ($advProperties) {
                    foreach ($property in $advProperties) {
                        Write-Host " $($property.DisplayName): $($property.DisplayValue)" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host " No advanced properties available for this adapter." -ForegroundColor Yellow
                }
            } catch {
                Write-Host " [-] Could not retrieve advanced properties: $_" -ForegroundColor Red
            }
            
            Write-Host
            Read-Host " Press Enter to continue"
            Get-InterfaceInfo
        }
        "0" {
            return
        }
        default {
            Write-Host " [-] Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Get-InterfaceInfo
        }
    }
}

function Configure-IPAddress {
    if (-not $global:selectedInterface) {
        Write-Host "`n No interface selected. Please select an interface first." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Select-NetworkInterface
        return
    }
    
    Show-Banner
    foreach ($line in $ipConfigMenu) {
        Write-Host ( Center-text $line)
    }

    Write-Host ""
    $choice = Read-Host " ♥ Please enter your choice"
    
    $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $global:selectedInterface }
    
    switch ($choice) {
        "1" {
            # Configure Static IPv4
            Clear-Host
            Write-Host "`n Configure Static IPv4 Address:" -ForegroundColor Green
            Write-Host " ------------------------------" -ForegroundColor Green
            
            $ipAddress = Read-Host "`n ► Enter IP Address (e.g., 192.168.1.100)"
            Write-Host ""
            $prefixLength = Read-Host " ► Enter Subnet Prefix Length (e.g., 24 for 255.255.255.0)"
            Write-Host ""
            $gateway = Read-Host " ► Enter Default Gateway (e.g., 192.168.1.1)"
            
            try {
                # Remove existing IPv4 address if any
                $existingIPs = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                foreach ($ip in $existingIPs) {
                    Remove-NetIPAddress -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                # Remove existing gateway if any
                $existingGW = Get-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
                if ($existingGW) {
                    Remove-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                # Set new IP address
                New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway -AddressFamily IPv4
                
                Write-Host " Static IPv4 address configured successfully." -ForegroundColor Green
            } catch {
                Write-Host "`n [-] Error configuring static IPv4 address: `n $_" -ForegroundColor Red
            }
            
            Read-Host -Prompt "`n Press Enter to continue"
            Configure-IPAddress
        }
        "2" {
            # Configure Static IPv6
            Clear-Host
            Write-Host "`n Configure Static IPv6 Address:" -ForegroundColor Green
            Write-Host " ------------------------------" -ForegroundColor Green
            Write-Host ""
            $ipAddress = Read-Host " ► Enter IPv6 Address (e.g., 2001:db8::100)"
            Write-Host ""
            $prefixLength = Read-Host " ► Enter Subnet Prefix Length (e.g., 64)"
            Write-Host ""
            $gateway = Read-Host " ► Enter Default Gateway (e.g., 2001:db8::1)"
            
            try {
                # Remove existing IPv6 address if any
                $existingIPs = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue | 
                               Where-Object { $_.PrefixOrigin -eq "Manual" }
                foreach ($ip in $existingIPs) {
                    Remove-NetIPAddress -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                # Remove existing gateway if any
                $existingGW = Get-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "::/0" -ErrorAction SilentlyContinue
                if ($existingGW) {
                    Remove-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "::/0" -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                # Set new IP address
                New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway -AddressFamily IPv6
                
                Write-Host "`n Static IPv6 address configured successfully." -ForegroundColor Green
            } catch {
                Write-Host "`n Error configuring static IPv6 address: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Configure-IPAddress
        }
        "3" {
            Clear-Host

            # Configure DHCP
            Write-Host "`n Configuring DHCP:" -ForegroundColor Green
            Write-Host " ----------------" -ForegroundColor Green
            
            try {
                # Remove existing IPv4 addresses and routes
                $existingIPs = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                foreach ($ip in $existingIPs) {
                    Remove-NetIPAddress -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                $existingGW = Get-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
                if ($existingGW) {
                    Remove-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
                }
                
                # Set interface to DHCP mode
                Set-NetIPInterface -InterfaceIndex $interface.ifIndex -Dhcp Enabled -AddressFamily IPv4
                
                # Handle DNS settings
                $dnsConfig = Read-Host "`n Do you want to use DHCP for DNS server assignment too? (Y/N)"
                if ($dnsConfig -eq "Y" -or $dnsConfig -eq "y") {
                    Set-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -ResetServerAddresses
                    Write-Host "`n DNS servers will be obtained automatically." -ForegroundColor Green
                }
                
                # Restart adapter to apply changes
                Restart-NetAdapter -InterfaceIndex $interface.ifIndex
                
                Write-Host "`n DHCP configuration applied successfully." -ForegroundColor Green
                Write-Host "`n Waiting for DHCP to assign an address..." -ForegroundColor Cyan
                
                Start-Sleep -Seconds 5
                $newIp = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                if ($newIp) {
                    Write-Host " New IP Address: $($newIp.IPAddress)" -ForegroundColor Green
                } else {
                    Write-Host "` [-] No IP address assigned yet. Check network connection." -ForegroundColor Yellow
                }
            } catch {
                Write-Host " [-] Error configuring DHCP: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Configure-IPAddress
        }
        "4" {
            Clear-Host

            # Add Additional IP Address            
            Write-Host "`n Add Additional IP Address:" -ForegroundColor Green
            Write-Host " -----------------------" -ForegroundColor Green
            
            $ipFamily = Read-Host " ► Enter IP version (4 or 6)"
            
            if ($ipFamily -eq "4") {
                $ipAddress = Read-Host " ► Enter additional IPv4 Address (e.g., 192.168.1.101)"
                $prefixLength = Read-Host " ► Enter Subnet Prefix Length (e.g., 24 for 255.255.255.0)"
                
                try {
                    New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipAddress -PrefixLength $prefixLength -AddressFamily IPv4
                    Write-Host " Additional IPv4 address added successfully." -ForegroundColor Green
                } catch {
                    Write-Host " Error adding IPv4 address: $_" -ForegroundColor Red
                }
            } elseif ($ipFamily -eq "6") {
                $ipAddress = Read-Host " ► Enter additional IPv6 Address (e.g., 2001:db8::101)"
                $prefixLength = Read-Host " ► Enter Subnet Prefix Length (e.g., 64)"
                
                try {
                    New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $ipAddress -PrefixLength $prefixLength -AddressFamily IPv6
                    Write-Host " Additional IPv6 address added successfully." -ForegroundColor Green
                } catch {
                    Write-Host " [-] Error adding IPv6 address: $_" -ForegroundColor Red
                }
            } else {
                Write-Host " [-] Invalid IP version. Please enter 4 or 6." -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Configure-IPAddress
        }
        "5" {
            Clear-Host

            # Configure DNS Servers
            Write-Host "`n Configure DNS Servers:" -ForegroundColor Green
            Write-Host " ---------------------" -ForegroundColor Green
            
            $manualDns = Read-Host " ► Enter primary DNS server (e.g., 8.8.8.8)"
            $secondaryDns = Read-Host "`n ► Enter secondary DNS server (optional)"
            
            try {
                if ([string]::IsNullOrWhiteSpace($secondaryDns)) {
                    Set-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -ServerAddresses $manualDns
                } else {
                    Set-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -ServerAddresses $manualDns,$secondaryDns
                }
                Write-Host ""
                Write-Host " DNS servers configured successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error configuring DNS servers: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Configure-IPAddress
        }
        "6" {
            Clear-Host

            # View Current Configuration
            Write-Host "`n Current IP Configuration:" -ForegroundColor Green
            Write-Host " -----------------------" -ForegroundColor Green
            
            $ipConfig = Get-NetIPConfiguration -InterfaceIndex $interface.ifIndex
            
            Write-Host " Interface: $($ipConfig.InterfaceAlias)" -ForegroundColor Cyan
            Write-Host " Status: $($interface.Status)" -ForegroundColor Cyan
            
            # IPv4 Configuration
            $ipv4 = $ipConfig.IPv4Address
            if ($ipv4) {
                Write-Host "`n IPv4 Configuration:" -ForegroundColor Green
                foreach ($ip in $ipv4) {
                    Write-Host "  IP Address: $($ip.IPAddress)" -ForegroundColor Cyan
                    Write-Host "  Subnet Mask: /$($ip.PrefixLength)" -ForegroundColor Cyan
                }
                
                if ($ipConfig.IPv4DefaultGateway) {
                    Write-Host "  Default Gateway: $($ipConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor Cyan
                } else {
                    Write-Host "  No Default Gateway configured." -ForegroundColor Yellow
                }
            } else {
                Write-Host "`n No IPv4 configuration found." -ForegroundColor Yellow
            }
            
            # IPv6 Configuration
            $ipv6 = $ipConfig.IPv6Address
            if ($ipv6) {
                Write-Host "`n IPv6 Configuration:" -ForegroundColor Green
                foreach ($ip in $ipv6) {
                    Write-Host "  IP Address: $($ip.IPAddress)" -ForegroundColor Cyan
                    Write-Host "  Prefix Length: $($ip.PrefixLength)" -ForegroundColor Cyan
                }
                
                if ($ipConfig.IPv6DefaultGateway) {
                    Write-Host "  Default Gateway: $($ipConfig.IPv6DefaultGateway.NextHop)" -ForegroundColor Cyan
                } else {
                    Write-Host "  No IPv6 Default Gateway configured." -ForegroundColor Yellow
                }
            } else {
                Write-Host "`n No IPv6 configuration found." -ForegroundColor Yellow
            }
            
            # DNS Configuration
            Write-Host "`n DNS Configuration:" -ForegroundColor Green
            if ($ipConfig.DNSServer) {
                $dnsServers = $ipConfig.DNSServer.ServerAddresses
                if ($dnsServers) {
                    for ($i = 0; $i -lt $dnsServers.Count; $i++) {
                        Write-Host "  DNS Server $($i+1): $($dnsServers[$i])" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host " No DNS servers configured." -ForegroundColor Yellow
                }
            } else {
                Write-Host " No DNS servers configured." -ForegroundColor Yellow
            }
            
            # DHCP Status
            try {
                $dhcpv4 = Get-NetIPInterface -InterfaceIndex $interface.ifIndex -AddressFamily IPv4
                $dhcpv6 = Get-NetIPInterface -InterfaceIndex $interface.ifIndex -AddressFamily IPv6
                
                Write-Host "`n DHCP Status:" -ForegroundColor Green
                Write-Host "  IPv4 DHCP: $($dhcpv4.Dhcp)" -ForegroundColor Cyan
                Write-Host "  IPv6 DHCP: $($dhcpv6.Dhcp)" -ForegroundColor Cyan
            } catch {
                Write-Host "  Could not determine DHCP status." -ForegroundColor Yellow
            }
            
            Read-Host "`n Press Enter to continue"
            Configure-IPAddress
        }
        "0" {
            return
        }
        default {
            Write-Host "`n Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Configure-IPAddress
        }
    }
}

function Run-NetworkDiagnostics {
    if (-not $global:selectedInterface) {
        Write-Host "`n No interface selected. Please select an interface first." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Select-NetworkInterface
        return
    }
    
    Show-Banner
    foreach ($line in $diagnosticsMenu) {
        Write-Host (Center-text $line)
    }

    Write-Host  ""
    $choice = Read-Host "`n ♥ Please enter your choice"
    
    $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $global:selectedInterface }
    
    switch ($choice) {
        "1" {
            Clear-Host

            # Ping Test
            Write-Host "`n Ping Test:" -ForegroundColor Green
            Write-Host " ----------" -ForegroundColor Green
            
            Write-Host ""
            $target = Read-Host " ► Enter target IP or hostname to ping"
            Write-Host
            try {
                Test-Connection -ComputerName $target -Count 4 -ErrorAction Stop | ForEach-Object {
                    Write-Host "   Reply from $($_.Address): bytes=$($_.BufferSize) time=$($_.ResponseTime)ms TTL=$($_.TimeToLive)" -ForegroundColor Cyan
                }
            } catch {
                Write-Host "`n Ping failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "2" {
            Clear-Host

            # Trace Route
            Write-Host "`n Trace Route:" -ForegroundColor Green
            Write-Host " ------------" -ForegroundColor Green

            Write-Host ""
            $target = Read-Host " ► Enter target IP or hostname to trace"
            try {
                Test-NetConnection -TraceRoute $target -ErrorAction Stop | ForEach-Object {
                    Write-Host "`n Hop $($_.Hop): $($_.Address) - $($_.ResponseTime)ms" -ForegroundColor Cyan
                }
            } catch {
                Write-Host "`n Trace route failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            #Run-NetworkDiagnostics
        }
        "3" {
            Clear-Host

            # DNS Lookup
            Write-Host "`n DNS Lookup:" -ForegroundColor Green
            Write-Host " ----------" -ForegroundColor Green
            
            $hostname = Read-Host "`n ► Enter hostname to resolve"
            try {
                $dnsResult = Resolve-DnsName -Name $hostname -ErrorAction Stop
                foreach ($record in $dnsResult) {
                    Write-Host "`n Name: $($record.Name), Type: $($record.Type), Address: $($record.IPAddress)" -ForegroundColor Cyan
                }
            } catch {
                Write-Host "`n DNS lookup failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "4" {
            Clear-Host 

            # Run Network Speed Test
            Write-Host "`n Network Speed Test:" -ForegroundColor Green
            Write-Host " -------------------" -ForegroundColor Green
            
            Write-Host " This feature requires an external tool like iPerf or Speedtest CLI." -ForegroundColor Yellow
            Write-Host "`n Please install the required tool and configure it to use this script." -ForegroundColor Yellow
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "5" {
            Clear-Host

            # Check for Network Connectivity
            Write-Host "`n Network Connectivity Check:" -ForegroundColor Green
            Write-Host " -------------------------" -ForegroundColor Green
            
            try {
                $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction Stop
                if ($pingResult) {
                    Write-Host " Network is connected and reachable." -ForegroundColor Green
                } else {
                    Write-Host " Network is not reachable." -ForegroundColor Red
                }
            } catch {
                Write-Host " Network connectivity check failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "6" {
            Clear-Host

            # Test Port Connectivity
            Write-Host "`n Port Connectivity Test:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            $target = Read-Host "`n ► Enter target IP or hostname"
            $port = Read-Host " ► Enter port number to test"
            
            try {
                $portTest = Test-NetConnection -ComputerName $target -Port $port -ErrorAction Stop
                if ($portTest.TcpTestSucceeded) {
                    Write-Host "`n Port $port is open on $target." -ForegroundColor Green
                } else {
                    Write-Host "`n Port $port is closed or unreachable on $target." -ForegroundColor Red
                }
            } catch {
                Write-Host " Port test failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "7" {
            Clear-Host

            # View Connection Statistics
            Write-Host "`n Connection Statistics:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            try {
                $stats = Get-NetAdapterStatistics -InterfaceIndex $interface.ifIndex -ErrorAction Stop
                Write-Host " Bytes Sent: $($stats.SentBytes)" -ForegroundColor Cyan
                Write-Host " Bytes Received: $($stats.ReceivedBytes)" -ForegroundColor Cyan
                Write-Host " Packets Sent: $($stats.SentPackets)" -ForegroundColor Cyan
                Write-Host " Packets Received: $($stats.ReceivedPackets)" -ForegroundColor Cyan
            } catch {
                Write-Host "`n [-] Could not retrieve connection statistics: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "0" {
            return
        }
        default {
            Write-Host "`n Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Run-NetworkDiagnostics
        }
    }
}

function Manage-NetworkProfiles {
    Show-Banner
    foreach ($line in $profilesMenu) {
        Write-Host (Center-text $line)
    }

    Write-Host
    $choice = Read-Host " ♥ Please enter your choice"
    
    switch ($choice) {
        "1" {
            Clear-Host

            # Save Current Configuration
            Write-Host "`n Save Current Configuration:" -ForegroundColor Green
            Write-Host " --------------------------" -ForegroundColor Green
            
            $profileName = Read-Host " ► Enter a name for this profile"
            
            if ($global:selectedInterface) {
                $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $global:selectedInterface }
                $ipConfig = Get-NetIPConfiguration -InterfaceIndex $interface.ifIndex
                
                $profile = @{
                    Interface = $interface.InterfaceDescription
                    IPAddress = $ipConfig.IPv4Address.IPAddress
                    SubnetMask = $ipConfig.IPv4Address.PrefixLength
                    Gateway = $ipConfig.IPv4DefaultGateway.NextHop
                    DNSServers = $ipConfig.DNSServer.ServerAddresses
                }
                
                $global:savedProfiles[$profileName] = $profile
                try {
                    $global:savedProfiles | Export-Clixml -Path $global:profilesPath
                    Write-Host "`n Profile saved successfully." -ForegroundColor Green
                } catch {
                    Write-Host " Error saving profile: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "`n No interface selected. Please select an interface first." -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-NetworkProfiles
        }
        "2" {
            Clear-Host

            # Load Saved Profile
            Write-Host "`n Load Saved Profile:" -ForegroundColor Green
            Write-Host " ------------------" -ForegroundColor Green
            
            if ($global:savedProfiles.Count -eq 0) {
                Write-Host "No profiles saved." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
                Manage-NetworkProfiles
                return
            }
            
            Write-Host "Saved Profiles:" -ForegroundColor Green
            foreach ($key in $global:savedProfiles.Keys) {
                Write-Host "  $key" -ForegroundColor Cyan
            }
            
            $profileName = Read-Host "Enter the name of the profile to load"
            
            if ($global:savedProfiles.ContainsKey($profileName)) {
                $profile = $global:savedProfiles[$profileName]
                
                $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -eq $profile.Interface }
                if ($interface) {
                    try {
                        # Remove existing IP configuration
                        $existingIPs = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -ErrorAction SilentlyContinue
                        foreach ($ip in $existingIPs) {
                            Remove-NetIPAddress -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
                        }
                        
                        # Remove existing gateway
                        $existingGW = Get-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
                        if ($existingGW) {
                            Remove-NetRoute -InterfaceIndex $interface.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
                        }
                        
                        # Apply saved configuration
                        New-NetIPAddress -InterfaceIndex $interface.ifIndex -IPAddress $profile.IPAddress -PrefixLength $profile.SubnetMask -DefaultGateway $profile.Gateway -AddressFamily IPv4
                        Set-DnsClientServerAddress -InterfaceIndex $interface.ifIndex -ServerAddresses $profile.DNSServers
                        
                        Write-Host " Profile loaded successfully." -ForegroundColor Green
                    } catch {
                        Write-Host " Error loading profile: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host " Interface not found. Please ensure the interface is available." -ForegroundColor Red
                }
            } else {
                Write-Host " Profile not found." -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-NetworkProfiles
        }
        "3" {
            Clear-Host

            # Delete Saved Profile
            Write-Host "`n Delete Saved Profile:" -ForegroundColor Green
            Write-Host " --------------------" -ForegroundColor Green
            
            if ($global:savedProfiles.Count -eq 0) {
                Write-Host " No profiles saved." -ForegroundColor Yellow
                Read-Host " Press Enter to continue"
                Manage-NetworkProfiles
                return
            }
            
            Write-Host "Saved Profiles:" -ForegroundColor Green
            foreach ($key in $global:savedProfiles.Keys) {
                Write-Host "  $key" -ForegroundColor Cyan
            }
            
            $profileName = Read-Host " ► Enter the name of the profile to delete"
            
            if ($global:savedProfiles.ContainsKey($profileName)) {
                $global:savedProfiles.Remove($profileName)
                try {
                    $global:savedProfiles | Export-Clixml -Path $global:profilesPath
                    Write-Host " Profile deleted successfully." -ForegroundColor Green
                } catch {
                    Write-Host " Error deleting profile: $_" -ForegroundColor Red
                }
            } else {
                Write-Host " Profile not found." -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-NetworkProfiles
        }
        "4" {
            Clear-Host

            # View All Saved Profiles
            Write-Host "`nView All Saved Profiles:" -ForegroundColor Green
            Write-Host " -----------------------" -ForegroundColor Green
            
            if ($global:savedProfiles.Count -eq 0) {
                Write-Host "No profiles saved." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
                Manage-NetworkProfiles
                return
            }
            
            foreach ($key in $global:savedProfiles.Keys) {
                Write-Host "Profile: $key" -ForegroundColor Cyan
                $profile = $global:savedProfiles[$key]
                Write-Host "  Interface: $($profile.Interface)" -ForegroundColor Cyan
                Write-Host "  IP Address: $($profile.IPAddress)" -ForegroundColor Cyan
                Write-Host "  Subnet Mask: $($profile.SubnetMask)" -ForegroundColor Cyan
                Write-Host "  Gateway: $($profile.Gateway)" -ForegroundColor Cyan
                Write-Host "  DNS Servers: $($profile.DNSServers -join ', ')" -ForegroundColor Cyan
                Write-Host ""
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-NetworkProfiles
        }
        "0" {
            return
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Manage-NetworkProfiles
        }
    }
}

function Manage-WiFi {
    Show-Banner
    foreach ($line in $wifiMenu) {
        Write-Host ( Center-text $line)
    }
    Write-Host
    $choice = Read-Host " ♥ Please enter your choice"
    
    switch ($choice) {
        "1" {
            Clear-Host

            # View Available Networks
            Write-Host "`n Available Wi-Fi Networks:" -ForegroundColor Green
            Write-Host " -------------------------" -ForegroundColor Green
            
            try {
                $networks = netsh wlan show networks | Select-String "SSID"
                if ($networks) {
                    foreach ($network in $networks) {
                        Write-Host " $network" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host " No Wi-Fi networks found." -ForegroundColor Yellow
                }
            } catch {
                Write-Host " Error retrieving Wi-Fi networks: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "2" {
            Clear-Host

            # Connect to Wi-Fi Network
            Write-Host "`n Connect to Wi-Fi Network:" -ForegroundColor Green
            Write-Host " ------------------------" -ForegroundColor Green
            
            $ssid = Read-Host " ► Enter the SSID of the network to connect to"
            Write-Host
            $password = Read-Host " ► Enter the password (leave blank if open network)"
            Write-Host

            try {
                if ($password) {
                    $profileXml = @"
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
                    $profileXml | Out-File "$env:TEMP\$ssid.xml"
                    netsh wlan add profile filename="$env:TEMP\$ssid.xml"
                    Remove-Item "$env:TEMP\$ssid.xml"
                }
                
                netsh wlan connect name="$ssid"
                Write-Host " Connected to $ssid successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error connecting to Wi-Fi network: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "3" {
            Clear-Host

            # Disconnect from Wi-Fi
            Write-Host "`n Disconnect from Wi-Fi:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            try {
                netsh wlan disconnect
                Write-Host " Disconnected from Wi-Fi successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error disconnecting from Wi-Fi: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "4" {
            Clear-Host

            # Manage Saved Networks
            Write-Host "`n Manage Saved Wi-Fi Networks:" -ForegroundColor Green
            Write-Host " ---------------------------" -ForegroundColor Green
            
            try {
                $profiles = netsh wlan show profiles #| Out-String
                foreach ($line in $profiles) { Write-Host " $line" -ForegroundColor Cyan }
                
                $profileName = Read-Host " ► Enter the name of the profile to manage"
                Write-Host
                $action = Read-Host " ► Enter 'delete' to remove the profile or 'view' to see details"
                
                if ($action -eq "delete") {
                    netsh wlan delete profile name="$profileName"
                    Write-Host " Profile deleted successfully." -ForegroundColor Green
                } elseif ($action -eq "view") {
                    $profileNameOut = netsh wlan show profile name="$profileName" key=clear
                    foreach ($line in  $profileNameOut){ Write-Host " $line"}

                    # Process and display the profile details with leading spaces
                    $profileDetails = netsh wlan show profile name="$profileName" key=clear
                    foreach ($line in $profileDetails) {
                        # Check if this line contains the password
                        if ($line -match "Key Content" -or $line -match "Password") {
                            Write-Host " $line" -ForegroundColor Red
                        } else {
                            Write-Host " $line" -ForegroundColor Cyan
                        }
                    }
                } else {
                    Write-Host " Invalid action. Please enter 'delete' or 'view'." -ForegroundColor Red
                }
            } catch {
                Write-Host " Error managing Wi-Fi profiles: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "5" {
            Clear-Host

            # View Wi-Fi Signal Strength
            Write-Host "`n View Wi-Fi Signal Strength:" -ForegroundColor Green
            Write-Host " ---------------------------" -ForegroundColor Green
            
            try {
                $signal = netsh wlan show interfaces | Select-String "Signal"
                if ($signal) {
                    Write-Host $signal -ForegroundColor Cyan
                } else {
                    Write-Host " Could not retrieve signal strength." -ForegroundColor Yellow
                }
            } catch {
                Write-Host " Error retrieving signal strength: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "6" {
            Clear-Host

            # Create Wi-Fi Hotspot
            Write-Host "`n Create Wi-Fi Hotspot:" -ForegroundColor Green
            Write-Host " --------------------" -ForegroundColor Green
            
            $ssid = Read-Host " ► Enter the SSID for the hotspot"
            $password = Read-Host " ► Enter the password for the hotspot"
            
            try {
                $hotspotProfile = @"
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
                $hotspotProfile | Out-File "$env:TEMP\$ssid.xml"
                netsh wlan add profile filename="$env:TEMP\$ssid.xml"
                Remove-Item "$env:TEMP\$ssid.xml"
                
                netsh wlan start hostednetwork ssid="$ssid" key="$password"
                Write-Host " Hotspot '$ssid' created successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error creating hotspot: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-WiFi
        }
        "0" {
            return
        }
        default {
            Write-Host "`n Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Manage-WiFi
        }
    }
}
function Manage-Firewall {
    Show-Banner
    foreach ($line in $firewallMenu) {
        Write-Host (Center-text $line)
    }
    Write-Host
    $choice = Read-Host " ♥ Please enter your choice"
    
    switch ($choice) {
        "1" {
            Clear-Host

            # View Firewall Status
            Write-Host "`n Firewall Status:" -ForegroundColor Green
            Write-Host " --------------" -ForegroundColor Green
            
            try {
                $firewallStatus = Get-NetFirewallProfile
                foreach ($profile in $firewallStatus) {
                    Write-Host " $($profile.Name): $($profile.Enabled)" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error retrieving firewall status: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-Firewall
        }
        "2" {
            Clear-Host

            # Enable/Disable Firewall
            Write-Host "`n Enable/Disable Firewall:" -ForegroundColor Green
            Write-Host " ---------------------" -ForegroundColor Green
            
            $action = Read-Host " ► Enter 'enable' or 'disable'"
            $profile = Read-Host "`n ► Enter profile (Domain, Private, Public)"
            
            try {
                if ($action -eq "enable") {
                    Set-NetFirewallProfile -Name $profile -Enabled True
                    Write-Host " Firewall enabled for $profile profile." -ForegroundColor Green
                } elseif ($action -eq "disable") {
                    Set-NetFirewallProfile -Name $profile -Enabled False
                    Write-Host " Firewall disabled for $profile profile." -ForegroundColor Green
                } else {
                    Write-Host " Invalid action. Please enter 'enable' or 'disable'." -ForegroundColor Red
                }
            } catch {
                Write-Host "`n Error modifying firewall: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-Firewall
        }
        "3" {
            Clear-Host

            # Add Firewall Rule
            Write-Host "`n Add Firewall Rule:" -ForegroundColor Green
            Write-Host " ----------------" -ForegroundColor Green
            
            $ruleName = Read-Host " ► Enter rule name"
            $direction = Read-Host " ► Enter direction (Inbound/Outbound)"
            $action = Read-Host " ► Enter action (Allow/Block)"
            $protocol = Read-Host " ► Enter protocol (TCP/UDP)"
            $port = Read-Host " ► Enter port number"
            
            try {
                New-NetFirewallRule -DisplayName $ruleName -Direction $direction -Action $action -Protocol $protocol -LocalPort $port
                Write-Host " Firewall rule added successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error adding firewall rule: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-Firewall
        }
        "4" {
            Clear-Host

            # Remove Firewall Rule
            Write-Host "`n Remove Firewall Rule:" -ForegroundColor Green
            Write-Host " ---------------------" -ForegroundColor Green
            
            $ruleName = Read-Host " ► Enter rule name to remove"
            
            try {
                Remove-NetFirewallRule -DisplayName $ruleName
                Write-Host " Firewall rule removed successfully." -ForegroundColor Green
            } catch {
                Write-Host " Error removing firewall rule: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-Firewall
        }
        "5" {
            Clear-Host

            # View Active Firewall Rules
            Write-Host "`n Active Firewall Rules:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            try {
                $rules = Get-NetFirewallRule
                foreach ($rule in $rules) {
                    Write-Host " $($rule.DisplayName): $($rule.Direction), $($rule.Action), $($rule.Protocol), $($rule.LocalPort)" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error retrieving firewall rules: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Manage-Firewall
        }
        "0" {
            return
        }
        default {
            Write-Host " [-] Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Manage-Firewall
        }
    }
}
function Monitor-Network {
    Show-Banner
    foreach ($line in $monitoringMenu) {
        Write-Host (Center-text $line)
    }
    Write-Host ""
    Write-Host ""
    $choice = Read-Host " ♥ Please enter your choice"
    
    switch ($choice) {
        "1" {
            Clear-Host

            # Monitor Network Traffic
            Write-Host "`n Monitor Network Traffic:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            try {
                $traffic = Get-NetAdapterStatistics
                foreach ($adapter in $traffic) {
                    Write-Host " $($adapter.Name): Sent: $($adapter.SentBytes) bytes, Received: $($adapter.ReceivedBytes) bytes" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error monitoring network traffic: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Monitor-Network
        }
        "2" {
            Clear-Host

            # View Active Connections
            Write-Host "`n Active Connections:" -ForegroundColor Green
            Write-Host " ------------------" -ForegroundColor Green
            
            try {
                $connections = Get-NetTCPConnection
                foreach ($conn in $connections) {
                    Write-Host " Local: $($conn.LocalAddress):$($conn.LocalPort), Remote: $($conn.RemoteAddress):$($conn.RemotePort), State: $($conn.State)" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error retrieving active connections: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Monitor-Network
        }
        "3" {
            Clear-Host
            
            # View Bandwidth Usage
            Write-Host "`n Bandwidth Usage:" -ForegroundColor Green
            Write-Host " ---------------" -ForegroundColor Green
            
            try {
                $bandwidth = Get-NetAdapterStatistics
                foreach ($adapter in $bandwidth) {
                    Write-Host " $($adapter.Name): Sent: $($adapter.SentBytes) bytes, Received: $($adapter.ReceivedBytes) bytes" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error retrieving bandwidth usage: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Monitor-Network
        }
        "4" {
            Clear-Host

            # Network Performance Statistics
            Write-Host "`n Network Performance Statistics:" -ForegroundColor Green
            Write-Host " ------------------------------" -ForegroundColor Green
            
            try {
                $perfStats = Get-NetAdapterStatistics
                foreach ($adapter in $perfStats) {
                    Write-Host "$($adapter.Name): Sent: $($adapter.SentBytes) bytes, Received: $($adapter.ReceivedBytes) bytes" -ForegroundColor Cyan
                }
            } catch {
                Write-Host " Error retrieving performance statistics: $_" -ForegroundColor Red
            }
            
            Read-Host " Press Enter to continue"
            Monitor-Network
        }
        "5" {
            Clear-Host

            # Start Continuous Monitoring
            Write-Host "`n Continuous Network Monitoring:" -ForegroundColor Green
            Write-Host " ------------------------------" -ForegroundColor Green
            
            $duration = Read-Host " ► Enter duration in seconds (e.g., 60)"
            $interval = Read-Host " ► Enter interval in seconds (e.g., 5)"
            
            try {
                $endTime = (Get-Date).AddSeconds($duration)
                while ((Get-Date) -lt $endTime) {
                    Clear-Host
                    $traffic = Get-NetAdapterStatistics
                    foreach ($adapter in $traffic) {
                        Write-Host " $($adapter.Name): Sent: $($adapter.SentBytes) bytes, Received: $($adapter.ReceivedBytes) bytes" -ForegroundColor Cyan
                    }
                    Start-Sleep -Seconds $interval
                }
            } catch {
                Write-Host " Error during continuous monitoring: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Monitor-Network
        }
        "0" {
            return
        }
        default {
            Write-Host "`n Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Monitor-Network
        }
    }
}

# Main Script Loop
while ($true) {
    Show-Banner
    $choice = Show-Menu
    
    switch ($choice) {
        "1" { Select-NetworkInterface }
        "2" { Get-InterfaceInfo }
        "3" { Configure-IPAddress }
        "4" { Run-NetworkDiagnostics }
        "5" { Manage-NetworkProfiles }
        "6" { Manage-WiFi }
        "7" { Manage-Firewall }
        "8" { Monitor-Network }
        "9" { Select-NetworkInterface }
        "10" { break }
        default {
            Write-Host "`n Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
    if ($choice -eq "10") {
        Clear-Host
        #Write-Host "`n HAHA Aji lhena dkhol lhemam bhal kherojo"
        #Write-Host ""
        #$Bayena = Read-Host " Ara Chi bayena Osir"
        #Write-Host ""
        #Write-Host " ⊂(◉‿◉)つ "
        #Write-Host "`n A7777777 3lik"
        #Start-Sleep -Seconds 2
        #Write-Host ""

        Write-Host "`n Exiting the script. Goodbye!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        start https://github.com/j0oyboy
        clear-host
        break
    }
}