chcp 65001 > $null

function Custom-Window {
    # First, define the Window class for transparency
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Window {
    [DllImport("user32.dll")]
    public static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    public static void SetTransparency(IntPtr hwnd, byte opacity) {
        const int GWL_EXSTYLE = -20;
        const int WS_EX_LAYERED = 0x80000;
        const int LWA_ALPHA = 0x2;
        int style = GetWindowLong(hwnd, GWL_EXSTYLE);
        SetWindowLong(hwnd, GWL_EXSTYLE, style | WS_EX_LAYERED);
        SetLayeredWindowAttributes(hwnd, 0, opacity, LWA_ALPHA);
    }
}
"@
    # Get the PowerShell window handle
    $hwnd = (Get-Process -Id $PID).MainWindowHandle
    
    # Change window transparency (220/255 opacity)
    [Window]::SetTransparency($hwnd, 232)
    
    # Change Window Size (120x31 characters)
    [console]::SetWindowSize(120, 31)
    
    # Change window title
    $host.UI.RawUI.WindowTitle = "Advanced Network Tool"
    
    # Change colors
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Cyan"
    
    # Set font to Lucida Console size 16
    try {
        $null = $host.ui.rawui.FontFamily = "Lucida Console"
        $null = $host.ui.rawui.FontSize = 16
    } catch {
        $null = $_.Exception
    }
    
    # Apply changes
    Clear-Host
}

# Execute the function
Custom-Window


function Center-text ($text){
    $width = [console]::WindowWidth
    $padLef = [math]::Max(0,($width - $text.Length)) / 2
    return (' ' * $padLef) + $text
}

function Install-SpeedtestCLI {
    Write-Host "`n Speedtest CLI Installer" -ForegroundColor Green
    Write-Host " -----------------------" -ForegroundColor Green
    
    # Define URLs and paths
    $speedtestUrl = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"
    $downloadPath = Join-Path $env:TEMP "speedtest-cli.zip"
    $extractPath = Join-Path $env:TEMP "speedtest-cli"
    $installPath = Join-Path $env:ProgramFiles "Speedtest CLI"
    
    try {
        # Create directories if they don't exist
        if (-not (Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }
        
        if (-not (Test-Path $installPath)) {
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        }
        
        # Download Speedtest CLI
        Write-Host "`n Downloading Speedtest CLI..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $speedtestUrl -OutFile $downloadPath
        
        # Extract the ZIP file
        Write-Host "`n Extracting files..." -ForegroundColor Cyan
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        
        # Copy files to install location
        Write-Host " Installing to $installPath..." -ForegroundColor Cyan
        Copy-Item -Path "$extractPath\*" -Destination $installPath -Recurse -Force
        
        # Add to PATH if not already there
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$installPath*") {
            Write-Host " Adding to system PATH..." -ForegroundColor Cyan
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", "Machine")
        }
        
        # Accept license agreement (this is needed for Speedtest CLI to work)
        Write-Host " Accepting license agreement..." -ForegroundColor Cyan
        & "$installPath\speedtest.exe" --accept-license --accept-gdpr
        
        # Clean up
        Write-Host " Cleaning up temporary files..." -ForegroundColor Cyan
        Remove-Item -Path $downloadPath -Force
        Remove-Item -Path $extractPath -Recurse -Force
        
        # Verify installation
        $speedtestInstalled = Get-Command speedtest.exe -ErrorAction SilentlyContinue
        
        if ($speedtestInstalled) {
            Write-Host "`n ✓ Speedtest CLI has been successfully installed!" -ForegroundColor Green
            Write-Host "   You can now run 'speedtest' from any command prompt." -ForegroundColor Green
            return $true
        } else {
            Write-Host "`n ⚠️ Installation completed but Speedtest CLI may need a system restart to be recognized in PATH." -ForegroundColor Yellow
            Write-Host "   You can manually run it from: $installPath\speedtest.exe" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Host "`n [-] Error installing Speedtest CLI: $_" -ForegroundColor Red
        return $false
    }
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n This script requires administrator privileges." -ForegroundColor Red
    Write-Host "`n ☺ Please run PowerShell as administrator and try again..." -ForegroundColor Red
    Read-Host "`n Press Enter to exit"
    exit
}

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
    "╔═══════════════════════════════════════════════════╗",
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
    "╔════════════════════════════════════════╗",
    "║ 1. Ping Test                           ║",
    "║ 2. Trace Route                         ║",
    "║ 3. DNS Lookup                          ║",
    "║ 4. Run Network Speed Test              ║",
    "║ 5. Check for Network Connectivity      ║",
    "║ 6. Test Port Connectivity              ║",
    "║ 7. Network Configuration Information   ║",
    "║ 8. Export Network Diagnostics Report   ║",
    "║ 0. Return to Main Menu                 ║",
    "╚════════════════════════════════════════╝"
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
    "║ 6. View Connection Statistics          ║",
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
                    Write-Host "`n [-] No IP address assigned yet. Check network connection." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "`n [-] Error configuring DHCP: $_" -ForegroundColor Red
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
                Write-Host "`n [-] Invalid IP version. Please enter 4 or 6." -ForegroundColor Red
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
    
    Write-Host ""
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
            $count = Read-Host " ► Enter number of pings to send (default: 4)"
            
            if ([string]::IsNullOrWhiteSpace($count) -or -not [int]::TryParse($count, [ref]$null)) {
                $count = 4
            }
            
            Write-Host
            try {
                $pingResults = Test-Connection -ComputerName $target -Count $count -ErrorAction Stop
                
                # Calculate statistics
                $successful = ($pingResults | Where-Object { $_.StatusCode -eq 0 }).Count
                $failed = $count - $successful
                $avgTime = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
                
                foreach ($result in $pingResults) {
                    if ($result.StatusCode -eq 0) {
                        Write-Host "   Reply from $($result.Address): bytes=$($result.BufferSize) time=$($result.ResponseTime)ms TTL=$($result.TimeToLive)" -ForegroundColor Cyan
                    } else {
                        Write-Host "   Request timed out." -ForegroundColor Red
                    }
                }
                
                # Display summary
                Write-Host "`n Ping statistics for '$target':" -ForegroundColor Yellow
                Write-Host "   Packets: Sent = $count, Received = $successful, Lost = $failed ($(($failed/$count)*100)% loss)" -ForegroundColor Yellow
                if ($successful -gt 0) {
                    Write-Host "   Approximate round trip times in milliseconds:" -ForegroundColor Yellow
                    Write-Host "   Average = $([math]::Round($avgTime, 2))ms" -ForegroundColor Yellow
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
                Write-Host "`n Tracing route to $target..." -ForegroundColor Cyan
                
                $traceRoute = Test-NetConnection -TraceRoute -ComputerName $target -ErrorAction Stop
                
                # Display each hop with more formatting
                for ($i = 0; $i -lt $traceRoute.TraceRoute.Count; $i++) {
                    $hop = $traceRoute.TraceRoute[$i]
                    $hopNumber = $i + 1
                    
                    # Try to get hostname for the IP
                    $hostname = ""
                    try {
                        $dnsInfo = [System.Net.Dns]::GetHostEntry($hop)
                        $hostname = $dnsInfo.HostName
                    } catch {
                        # If reverse DNS lookup fails, just use the IP
                        $hostname = $hop
                    }
                    
                    Write-Host "   $hopNumber`t$hop`t$hostname" -ForegroundColor Cyan
                }
                
                Write-Host "`n Trace complete." -ForegroundColor Green
            } catch {
                Write-Host "`n Trace route failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "3" {
            Clear-Host

            # DNS Lookup
            Write-Host "`n DNS Lookup:" -ForegroundColor Green
            Write-Host " ----------" -ForegroundColor Green
            
            $hostname = Read-Host "`n ► Enter hostname to resolve"
            $recordType = Read-Host " ► Enter record type (A, AAAA, MX, NS, etc.) or leave blank for all"
            
            try {
                if ([string]::IsNullOrWhiteSpace($recordType)) {
                    $dnsResult = Resolve-DnsName -Name $hostname -ErrorAction Stop
                } else {
                    $dnsResult = Resolve-DnsName -Name $hostname -Type $recordType -ErrorAction Stop
                }
                
                Write-Host "`n DNS Records for $hostname" -ForegroundColor Yellow
                
                # Group by record type for cleaner output
                $dnsResult | Group-Object -Property Type | ForEach-Object {
                    Write-Host "`n   $($_.Name) Records:" -ForegroundColor Cyan
                    $_.Group | ForEach-Object {
                        # Choose what to display based on record type
                        switch ($_.Type) {
                            "A" { Write-Host "     Name: $($_.Name), Address: $($_.IPAddress)" }
                            "AAAA" { Write-Host "     Name: $($_.Name), Address: $($_.IPAddress)" }
                            "MX" { Write-Host "     Name: $($_.Name), Priority: $($_.Preference), Exchange: $($_.NameExchange)" }
                            "NS" { Write-Host "     Name: $($_.Name), NameServer: $($_.NameHost)" }
                            "SOA" { Write-Host "     Name: $($_.Name), PrimaryServer: $($_.PrimaryServer), Admin: $($_.ResponsiblePerson)" }
                            "TXT" { Write-Host "     Name: $($_.Name), Text: $($_.Strings)" }
                            default { Write-Host "     Name: $($_.Name), Data: $($_.Data)" }
                        }
                    }
                }
            } catch {
                Write-Host "`n DNS lookup failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
                }
        "4" {
            Clear-Host 

            # Network Speed Test
            Write-Host "`n Network Speed Test:" -ForegroundColor Green
            Write-Host " -------------------" -ForegroundColor Green
    
            # Try to find if Speedtest CLI is installed
            $speedtestInstalled = $null
            try {
                $speedtestInstalled = Get-Command speedtest.exe -ErrorAction SilentlyContinue
            } catch {
                # Command not found
            }
    
            if ($speedtestInstalled) {
                Write-Host "`n Running speed test using Speedtest CLI..." -ForegroundColor Cyan
                try {
                    $result = Invoke-Expression "speedtest.exe --format=json" | ConvertFrom-Json
            
                    Write-Host "`n Speed Test Results:" -ForegroundColor Yellow
                    Write-Host "   Server: $($result.server.name) ($($result.server.location))" -ForegroundColor Cyan
                    Write-Host "   Ping: $($result.ping.latency) ms" -ForegroundColor Cyan
                    Write-Host "   Download: $([math]::Round($result.download.bandwidth * 8 / 1000000, 2)) Mbps" -ForegroundColor Cyan
                    Write-Host "   Upload: $([math]::Round($result.upload.bandwidth * 8 / 1000000, 2)) Mbps" -ForegroundColor Cyan
                } catch {
                    Write-Host "`n Speed test failed: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "`n Speedtest CLI not found. Would you like to:" -ForegroundColor Yellow
                Write-Host "   1. Download and install Speedtest CLI automatically" -ForegroundColor Cyan
                Write-Host "   2. Use a basic bandwidth test between network interfaces" -ForegroundColor Cyan
                Write-Host "   3. Return to menu" -ForegroundColor Cyan
        
                $speedChoice = Read-Host "`n ► Enter your choice"
        
                switch ($speedChoice) {
                    "1" {
                        # Call the installer function
                        Write-Host "`n Starting automatic installation..." -ForegroundColor Cyan
                        $installSuccess = Install-SpeedtestCLI
                
                        if ($installSuccess) {
                            Write-Host "`n Would you like to run a speed test now? (Y/N)" -ForegroundColor Yellow
                            $runTest = Read-Host " ► "
                    
                            if ($runTest -eq "Y" -or $runTest -eq "y") {
                                Clear-Host
                                Write-Host "`n Running speed test..." -ForegroundColor Cyan
                                try {
                                    & speedtest.exe --format=json | ConvertFrom-Json | ForEach-Object {
                                        Write-Host "`n Speed Test Results:" -ForegroundColor Yellow
                                        Write-Host "   Server: $($_.server.name) ($($_.server.location))" -ForegroundColor Cyan
                                        Write-Host "   Ping: $($_.ping.latency) ms" -ForegroundColor Cyan
                                        Write-Host "   Download: $([math]::Round($_.download.bandwidth * 8 / 1000000, 2)) Mbps" -ForegroundColor Cyan
                                        Write-Host "   Upload: $([math]::Round($_.upload.bandwidth * 8 / 1000000, 2)) Mbps" -ForegroundColor Cyan
                                    }
                                } catch {
                                    Write-Host "`n Speed test failed: $_" -ForegroundColor Red
                                    Write-Host "   You may need to restart the script or computer for the installation to take full effect." -ForegroundColor Yellow
                                }
                            }
                        }
                    }
                    "2" {
                        Write-Host "`n Basic Network Performance:" -ForegroundColor Cyan
                        Write-Host "   Checking network adapter speed..." -ForegroundColor Cyan
                
                        $adapterInfo = Get-NetAdapter -InterfaceIndex $interface.ifIndex | Select-Object Name, InterfaceDescription, LinkSpeed
                        Write-Host "   Interface: $($adapterInfo.Name)" -ForegroundColor Cyan
                        Write-Host "   Link Speed: $($adapterInfo.LinkSpeed)" -ForegroundColor Cyan
                
                        # Get current network utilization (basic)
                        $startStats = Get-NetAdapterStatistics -InterfaceIndex $interface.ifIndex
                        Write-Host "   Measuring network activity for 5 seconds..." -ForegroundColor Cyan
                        Start-Sleep -Seconds 5
                        $endStats = Get-NetAdapterStatistics -InterfaceIndex $interface.ifIndex
                
                        $bytesSent = $endStats.SentBytes - $startStats.SentBytes
                        $bytesReceived = $endStats.ReceivedBytes - $startStats.ReceivedBytes
                
                        Write-Host "   Current Download: $([math]::Round($bytesReceived / 5 / 1024 / 1024 * 8, 2)) Mbps" -ForegroundColor Cyan
                        Write-Host "   Current Upload: $([math]::Round($bytesSent / 5 / 1024 / 1024 * 8, 2)) Mbps" -ForegroundColor Cyan
                    }
                    "3" {
                        # Return to menu
                    }
                }
            }
    
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }

        "5" {
            Clear-Host

            # Check for Network Connectivity
            Write-Host "`n Network Connectivity Check:" -ForegroundColor Green
            Write-Host " -------------------------" -ForegroundColor Green
            
            # Array of common public DNS servers to test
            $testTargets = @(
                @{Name = "Google DNS"; IP = "8.8.8.8"},
                @{Name = "Cloudflare DNS"; IP = "1.1.1.1"},
                @{Name = "Local Gateway"; IP = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Get-NetIPInterface | Where-Object { $_.InterfaceIndex -eq $interface.ifIndex }).IPv4Address}
            )
            
            # Test IPv4 connectivity
            Write-Host "`n Testing IPv4 Connectivity:" -ForegroundColor Yellow
            
            foreach ($target in $testTargets) {
                if ([string]::IsNullOrEmpty($target.IP)) {
                    continue
                }
                
                try {
                    $result = Test-Connection -ComputerName $target.IP -Count 2 -ErrorAction SilentlyContinue
                    if ($result) {
                        Write-Host "   ✓ $($target.Name) ($($target.IP)) is reachable. Avg response: $([math]::Round(($result | Measure-Object -Property ResponseTime -Average).Average, 2))ms" -ForegroundColor Green
                    } else {
                        Write-Host "   ✗ $($target.Name) ($($target.IP)) is not reachable." -ForegroundColor Red
                    }
                } catch {
                    Write-Host "   ✗ $($target.Name) ($($target.IP)) test failed: $_" -ForegroundColor Red
                }
            }
            
            # Check DNS resolution
            Write-Host "`n Testing DNS Resolution:" -ForegroundColor Yellow
            $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $interface.ifIndex | Where-Object { $_.AddressFamily -eq 2 }
            
            foreach ($dnsServer in $dnsServers.ServerAddresses) {
                Write-Host "   DNS Server: $dnsServer" -ForegroundColor Cyan
                try {
                    $dns = Resolve-DnsName -Name "www.google.com" -Server $dnsServer -ErrorAction Stop -Type A
                    Write-Host "     ✓ DNS resolution successful" -ForegroundColor Green
                } catch {
                    Write-Host "     ✗ DNS resolution failed: $_" -ForegroundColor Red
                }
            }
            
            # Check internet connectivity
            Write-Host "`n Testing Internet Connectivity:" -ForegroundColor Yellow
            try {
                $webTest = Invoke-WebRequest -Uri "http://www.google.com" -Method HEAD -TimeoutSec 5 -ErrorAction Stop
                Write-Host "   ✓ Internet connection is active. Response status: $($webTest.StatusCode)" -ForegroundColor Green
            } catch {
                Write-Host "   ✗ Internet connection test failed: $_" -ForegroundColor Red
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
            $timeout = Read-Host " ► Enter timeout in milliseconds (default: 3000)"
            
            if ([string]::IsNullOrWhiteSpace($timeout) -or -not [int]::TryParse($timeout, [ref]$null)) {
                $timeout = 3000
            }
            
            # Display common service info if available
            if ([int]::TryParse($port, [ref]$null)) {
                $commonPorts = @{
                    21 = "FTP"
                    22 = "SSH"
                    23 = "Telnet"
                    25 = "SMTP"
                    53 = "DNS"
                    80 = "HTTP"
                    443 = "HTTPS"
                    3389 = "RDP"
                    5900 = "VNC"
                }
                
                if ($commonPorts.ContainsKey([int]$port)) {
                    Write-Host "`n Port $port is commonly used for $($commonPorts[[int]$port])" -ForegroundColor Yellow
                }
            }
            
            try {
                Write-Host "`n Testing connection to $target on port $port..." -ForegroundColor Cyan
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $connect = $tcpClient.BeginConnect($target, [int]$port, $null, $null)
                $wait = $connect.AsyncWaitHandle.WaitOne($timeout, $false)
                
                if (!$wait) {
                    $tcpClient.Close()
                    Write-Host "`n Connection to $target on port $port timed out after $timeout ms." -ForegroundColor Red
                } elseif ($tcpClient.Connected) {
                    $tcpClient.EndConnect($connect)
                    $tcpClient.Close()
                    Write-Host "`n Port $port is open on $target." -ForegroundColor Green
                    
                    # Try to get service banner for common ports
                    if ($port -in @(21, 22, 25, 80, 443)) {
                        Write-Host "`n Trying to retrieve service banner..." -ForegroundColor Cyan
                        try {
                            $client = New-Object System.Net.Sockets.TcpClient($target, [int]$port)
                            $stream = $client.GetStream()
                            $stream.ReadTimeout = 5000
                            
                            # For HTTP/HTTPS, send a simple request
                            if ($port -in @(80, 443)) {
                                $writer = New-Object System.IO.StreamWriter($stream)
                                $writer.WriteLine("HEAD / HTTP/1.1")
                                $writer.WriteLine("Host: $target")
                                $writer.WriteLine("Connection: close")
                                $writer.WriteLine("")
                                $writer.Flush()
                            }
                            
                            $reader = New-Object System.IO.StreamReader($stream)
                            $response = $reader.ReadLine()
                            Write-Host "   Banner: $response" -ForegroundColor Cyan
                            $client.Close()
                        } catch {
                            Write-Host "   Unable to retrieve service banner" -ForegroundColor Yellow
                        }
                    }
                } else {
                    Write-Host "`n Port $port is closed or unreachable on $target." -ForegroundColor Red
                }
            } catch {
                Write-Host "`n Port test failed: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        
        "7" {
            Clear-Host
            
            # Network Configuration Information
            Write-Host "`n Network Configuration:" -ForegroundColor Green
            Write-Host " ----------------------" -ForegroundColor Green
            
            try {
                $adapterConfig = Get-NetIPConfiguration -InterfaceIndex $interface.ifIndex -Detailed
                
                Write-Host "`n Interface Details:" -ForegroundColor Yellow
                Write-Host "   Name: $($adapterConfig.InterfaceAlias)" -ForegroundColor Cyan
                Write-Host "   Description: $($adapterConfig.InterfaceDescription)" -ForegroundColor Cyan
                Write-Host "   Status: $($adapterConfig.NetAdapter.Status)" -ForegroundColor Cyan
                Write-Host "   MAC Address: $($adapterConfig.NetAdapter.MacAddress)" -ForegroundColor Cyan
                Write-Host "   Interface Type: $($adapterConfig.NetAdapter.MediaType)" -ForegroundColor Cyan
                
                Write-Host "`n IPv4 Configuration:" -ForegroundColor Yellow
                Write-Host "   IP Address: $($adapterConfig.IPv4Address.IPAddress)" -ForegroundColor Cyan
                Write-Host "   Subnet Mask: $($adapterConfig.IPv4Address.PrefixLength)" -ForegroundColor Cyan
                Write-Host "   Default Gateway: $($adapterConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor Cyan
                Write-Host "   DHCP Enabled: $($adapterConfig.NetIPv4Interface.DHCP)" -ForegroundColor Cyan
                
                if ($adapterConfig.DNSServer) {
                    Write-Host "`n DNS Configuration:" -ForegroundColor Yellow
                    foreach ($dnsServer in $adapterConfig.DNSServer) {
                        if ($dnsServer.ServerAddresses) {
                            foreach ($address in $dnsServer.ServerAddresses) {
                                Write-Host "   DNS Server: $address" -ForegroundColor Cyan
                            }
                        }
                    }
                }
                
                # Get network profile info
                $networkProfile = Get-NetConnectionProfile -InterfaceIndex $interface.ifIndex
                
                Write-Host "`n Network Profile:" -ForegroundColor Yellow
                Write-Host "   Name: $($networkProfile.Name)" -ForegroundColor Cyan
                Write-Host "   Network Category: $($networkProfile.NetworkCategory)" -ForegroundColor Cyan
                
                # Network drivers info
                Write-Host "`n Network Driver Information:" -ForegroundColor Yellow
                $driverInfo = Get-NetAdapter -InterfaceIndex $interface.ifIndex | Get-NetAdapterAdvancedProperty
                
                if ($driverInfo) {
                    $driverInfo | Format-Table -Property DisplayName, DisplayValue -AutoSize | Out-Host
                } else {
                    Write-Host "   No advanced driver properties available." -ForegroundColor Cyan
                }
                
            } catch {
                Write-Host "`n [-] Could not retrieve network configuration: $_" -ForegroundColor Red
            }
            
            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "8" {
            Clear-Host
            
            # Export Network Diagnostics Report
            Write-Host "`n Export Network Diagnostics Report:" -ForegroundColor Green
            Write-Host " --------------------------------" -ForegroundColor Green
            
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $reportFile = "$env:USERPROFILE\Desktop\NetworkDiagnostics_$timestamp.html"
            
            try {
                Write-Host "`n Generating comprehensive network diagnostics report..." -ForegroundColor Cyan
                
                # Create HTML report
                $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Network Diagnostics Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .section { margin-bottom: 20px; border: 1px solid #ddd; padding: 10px; border-radius: 5px; }
        h1 { color: #2c3e50; }
        h2 { color: #3498db; }
        table { border-collapse: collapse; width: 100%; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:hover { background-color: #f5f5f5; }
        .good { color: green; }
        .bad { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Network Diagnostics Report</h1>
    <div class="section">
        <h2>Report Information</h2>
        <p><strong>Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Computer Name:</strong> $env:COMPUTERNAME</p>
        <p><strong>User:</strong> $env:USERNAME</p>
    </div>
"@

                # Add Network Adapter Information
                $adapterInfo = Get-NetAdapter -InterfaceIndex $interface.ifIndex
                $htmlReport += @"
    <div class="section">
        <h2>Network Adapter Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Name</td><td>$($adapterInfo.Name)</td></tr>
            <tr><td>Description</td><td>$($adapterInfo.InterfaceDescription)</td></tr>
            <tr><td>MAC Address</td><td>$($adapterInfo.MacAddress)</td></tr>
            <tr><td>Status</td><td>$($adapterInfo.Status)</td></tr>
            <tr><td>Link Speed</td><td>$($adapterInfo.LinkSpeed)</td></tr>
            <tr><td>Media Type</td><td>$($adapterInfo.MediaType)</td></tr>
        </table>
    </div>
"@

                # Add IP Configuration
                $ipConfig = Get-NetIPConfiguration -InterfaceIndex $interface.ifIndex
                $htmlReport += @"
    <div class="section">
        <h2>IP Configuration</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
"@
                
                if ($ipConfig.IPv4Address) {
                    $htmlReport += "<tr><td>IPv4 Address</td><td>$($ipConfig.IPv4Address.IPAddress)</td></tr>"
                    $htmlReport += "<tr><td>Subnet Mask</td><td>$($ipConfig.IPv4Address.PrefixLength)</td></tr>"
                }
                
                if ($ipConfig.IPv4DefaultGateway) {
                    $htmlReport += "<tr><td>Default Gateway</td><td>$($ipConfig.IPv4DefaultGateway.NextHop)</td></tr>"
                }
                
                if ($ipConfig.DNSServer) {
                    $dnsServers = $ipConfig.DNSServer.ServerAddresses -join ", "
                    $htmlReport += "<tr><td>DNS Servers</td><td>$dnsServers</td></tr>"
                }
                
                $htmlReport += @"
        </table>
    </div>
"@

                # Add Connection Statistics
                $stats = Get-NetAdapterStatistics -InterfaceIndex $interface.ifIndex
                
                function Format-BytesHTML {
                    param([long]$Bytes)
                    if ($Bytes -ge 1TB) { "{0:N2} TB" -f ($Bytes / 1TB) }
                    elseif ($Bytes -ge 1GB) { "{0:N2} GB" -f ($Bytes / 1GB) }
                    elseif ($Bytes -ge 1MB) { "{0:N2} MB" -f ($Bytes / 1MB) }
                    elseif ($Bytes -ge 1KB) { "{0:N2} KB" -f ($Bytes / 1KB) }
                    else { "{0} Bytes" -f $Bytes }
                }
                
                $htmlReport += @"
    <div class="section">
        <h2>Connection Statistics</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Sent Bytes</td><td>$(Format-BytesHTML $stats.SentBytes)</td></tr>
            <tr><td>Received Bytes</td><td>$(Format-BytesHTML $stats.ReceivedBytes)</td></tr>
            <tr><td>Sent Packets</td><td>$($stats.SentPackets)</td></tr>
            <tr><td>Received Packets</td><td>$($stats.ReceivedPackets)</td></tr>
            <tr><td>Send Errors</td><td>$($stats.SentPacketsDiscarded)</td></tr>
            <tr><td>Receive Errors</td><td>$($stats.ReceivedPacketsDiscarded)</td></tr>
        </table>
    </div>
"@

                # Add Network Connectivity Test Results
                $htmlReport += @"
    <div class="section">
        <h2>Network Connectivity Test</h2>
        <table>
            <tr><th>Target</th><th>Result</th></tr>
"@

                $testTargets = @(
                    @{Name = "Google DNS"; IP = "8.8.8.8"},
                    @{Name = "Cloudflare DNS"; IP = "1.1.1.1"},
                    @{Name = "Local Gateway"; IP = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Get-NetIPInterface | Where-Object { $_.InterfaceIndex -eq $interface.ifIndex }).IPv4Address}
                )

                foreach ($target in $testTargets) {
                    if ([string]::IsNullOrEmpty($target.IP)) {
                        continue
                    }

                    try {
                        $result = Test-Connection -ComputerName $target.IP -Count 2 -ErrorAction SilentlyContinue
                        if ($result) {
                            $htmlReport += "<tr><td>$($target.Name) ($($target.IP))</td><td class='good'>Reachable. Avg response: $([math]::Round(($result | Measure-Object -Property ResponseTime -Average).Average, 2))ms</td></tr>"
                        } else {
                            $htmlReport += "<tr><td>$($target.Name) ($($target.IP))</td><td class='bad'>Not reachable</td></tr>"
                        }
                    } catch {
                        $htmlReport += "<tr><td>$($target.Name) ($($target.IP))</td><td class='bad'>Test failed: $_</td></tr>"
                    }
                }

                $htmlReport += @"
        </table>
    </div>
"@

                # Add DNS Resolution Test Results
                $htmlReport += @"
    <div class="section">
        <h2>DNS Resolution Test</h2>
        <table>
            <tr><th>DNS Server</th><th>Result</th></tr>
"@

                $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $interface.ifIndex | Where-Object { $_.AddressFamily -eq 2 }

                foreach ($dnsServer in $dnsServers.ServerAddresses) {
                    try {
                        $dns = Resolve-DnsName -Name "www.google.com" -Server $dnsServer -ErrorAction Stop -Type A
                        $htmlReport += "<tr><td>$dnsServer</td><td class='good'>DNS resolution successful</td></tr>"
                    } catch {
                        $htmlReport += "<tr><td>$dnsServer</td><td class='bad'>DNS resolution failed: $_</td></tr>"
                    }
                }

                $htmlReport += @"
        </table>
    </div>
"@

                # Add Internet Connectivity Test Results
                $htmlReport += @"
    <div class="section">
        <h2>Internet Connectivity Test</h2>
        <table>
            <tr><th>Test</th><th>Result</th></tr>
"@

                try {
                    $webTest = Invoke-WebRequest -Uri "http://www.google.com" -Method HEAD -TimeoutSec 5 -ErrorAction Stop
                    $htmlReport += "<tr><td>HTTP Request to www.google.com</td><td class='good'>Internet connection is active. Response status: $($webTest.StatusCode)</td></tr>"
                } catch {
                    $htmlReport += "<tr><td>HTTP Request to www.google.com</td><td class='bad'>Internet connection test failed: $_</td></tr>"
                }

                $htmlReport += @"
        </table>
    </div>
"@

                # Add TCP Connections
                $htmlReport += @"
    <div class="section">
        <h2>Current TCP Connections</h2>
        <table>
            <tr><th>Local Address</th><th>Local Port</th><th>Remote Address</th><th>Remote Port</th><th>State</th><th>Process</th></tr>
"@

                $connections = Get-NetTCPConnection | Where-Object { $_.LocalAddress -notlike "*:*" -and $_.State -eq "Established" } | 
                               Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).Name}} |
                               Sort-Object LocalPort | Select-Object -First 10

                if ($connections.Count -gt 0) {
                    foreach ($conn in $connections) {
                        $htmlReport += "<tr><td>$($conn.LocalAddress)</td><td>$($conn.LocalPort)</td><td>$($conn.RemoteAddress)</td><td>$($conn.RemotePort)</td><td>$($conn.State)</td><td>$($conn.Process)</td></tr>"
                    }
                } else {
                    $htmlReport += "<tr><td colspan='6'>No established TCP connections found.</td></tr>"
                }

                $htmlReport += @"
        </table>
    </div>
"@

                # Close the HTML report
                $htmlReport += @"
</body>
</html>
"@

                # Save the report to a file
                $htmlReport | Out-File -FilePath $reportFile -Encoding UTF8
                Write-Host "`n Report saved to: $reportFile" -ForegroundColor Green

            } catch {
                Write-Host "`n [-] Could not generate report: $_" -ForegroundColor Red
            }

            Read-Host "`n Press Enter to continue"
            Run-NetworkDiagnostics
        }
        "0" {
            Clear-Host
            return
        }
        default {
            Write-Host "`n Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
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
                Write-Host " No profiles saved." -ForegroundColor Yellow
                Read-Host "`n Press Enter to continue"
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
            Write-Host "`n View All Saved Profiles:" -ForegroundColor Green
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
            Write-Host "`n Invalid option. Please try again." -ForegroundColor Red
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
                    Write-Host "`n Invalid action. Please enter 'delete' or 'view'." -ForegroundColor Red
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
                    Write-Host "`n Firewall disabled for $profile profile." -ForegroundColor Green
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
            # Monitor Network Traffic - Focus on packets and current activity
            $title = "Monitor Network Traffic"
            $action = {
                try {
                    $adapters = Get-NetAdapter | Where-Object Status -eq "Up"
                    if ($adapters.Count -eq 0) {
                        Write-Host " No active network adapters found." -ForegroundColor Yellow
                        return
                    }
                    
                    foreach ($adapter in $adapters) {
                        $stats = Get-NetAdapterStatistics -Name $adapter.Name
                        
                        Write-Host "`n Network Adapter: $($adapter.Name)" -ForegroundColor White
                        Write-Host " Status: $($adapter.Status) | Media Type: $($adapter.MediaType)" -ForegroundColor Cyan
                        
                        Write-Host "`n Traffic Summary:" -ForegroundColor Yellow
                        Write-Host "   Packets Sent: $($stats.SentPackets)" -ForegroundColor Cyan
                        Write-Host "   Packets Received: $($stats.ReceivedPackets)" -ForegroundColor Cyan
                        
                        Write-Host "`n Errors:" -ForegroundColor Yellow
                        Write-Host "   Send Errors: $($stats.SentPacketsDiscarded)" -ForegroundColor Cyan
                        Write-Host "   Receive Errors: $($stats.ReceivedPacketsDiscarded)" -ForegroundColor Cyan
                        
                        # Get active connections for this adapter
                        $connections = Get-NetTCPConnection | 
                            Where-Object { $_.State -eq "Established" } | 
                            Select-Object -First 5
                        
                        Write-Host "`n Current Active Connections (Top 5):" -ForegroundColor Yellow
                        if ($connections.Count -gt 0) {
                            foreach ($conn in $connections) {
                                $process = "Unknown"
                                try {
                                    $process = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).Name
                                    if (-not $process) { $process = "Unknown" }
                                } catch {}
                                
                                Write-Host "   $($conn.LocalAddress):$($conn.LocalPort) ↔ $($conn.RemoteAddress):$($conn.RemotePort) | $($conn.State) | Process: $process" -ForegroundColor Cyan
                            }
                        } else {
                            Write-Host "   No established connections found." -ForegroundColor Cyan
                        }
                    }
                } catch {
                    Write-Error-Message "Error retrieving network traffic information" $_
                }
            }
            Perform-NetworkAction -Title $title -Action $action
        }
        "2" {
            # View Active Connections
            $title = "Active Connections"
            $action = {
                try {
                    $connections = Get-NetTCPConnection
                    if ($connections.Count -eq 0) {
                        Write-Host " No active connections found." -ForegroundColor Yellow
                    } else {
                        # Group by state
                        $groupedConnections = $connections | Group-Object -Property State
                        
                        foreach ($group in $groupedConnections) {
                            Write-Host "`n $($group.Name) Connections ($($group.Count)):" -ForegroundColor Yellow
                            
                            # For established connections, show more details including process
                            if ($group.Name -eq "Established") {
                                $estConnections = $group.Group | 
                                    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, @{Name="Process";Expression={
                                        try { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name } 
                                        catch { "Unknown" }
                                    }} | Sort-Object RemoteAddress
                                
                                $estConnections | Format-Table -AutoSize | Out-Host
                            } else {
                                # For other states, just show the basic info
                                $group.Group | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort |
                                    Format-Table -AutoSize | Out-Host
                            }
                        }
                        
                        # Show connection count summary
                        Write-Host "`n Connection Summary:" -ForegroundColor Green
                        foreach ($group in $groupedConnections) {
                            Write-Host "   $($group.Name): $($group.Count) connections" -ForegroundColor Cyan
                        }
                        Write-Host "   Total: $($connections.Count) connections" -ForegroundColor Cyan
                    }
                } catch {
                    Write-Error-Message "Error retrieving active connections" $_
                }
            }
            Perform-NetworkAction -Title $title -Action $action
        }
        "3" {
            # Bandwidth Usage - Focus on data transfer rates and volumes
            $title = "Bandwidth Usage"
            $action = {
                try {
                    $adapters = Get-NetAdapter | Where-Object Status -eq "Up"
                    if ($adapters.Count -eq 0) {
                        Write-Host " No active network adapters found." -ForegroundColor Yellow
                        return
                    }
                    
                    # Get initial readings
                    $initialStats = @{}
                    foreach ($adapter in $adapters) {
                        $stats = Get-NetAdapterStatistics -Name $adapter.Name
                        $initialStats[$adapter.Name] = @{
                            SentBytes = $stats.SentBytes
                            ReceivedBytes = $stats.ReceivedBytes
                            Time = Get-Date
                        }
                    }
                    
                    # Wait a few seconds to calculate rates
                    Write-Host " Measuring bandwidth usage..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                    
                    foreach ($adapter in $adapters) {
                        $currentStats = Get-NetAdapterStatistics -Name $adapter.Name
                        $initial = $initialStats[$adapter.Name]
                        
                        # Calculate time difference in seconds
                        $timeSpan = (Get-Date) - $initial.Time
                        $seconds = $timeSpan.TotalSeconds
                        
                        # Calculate data transferred
                        $sentBytes = $currentStats.SentBytes - $initial.SentBytes
                        $receivedBytes = $currentStats.ReceivedBytes - $initial.ReceivedBytes
                        
                        # Calculate rates (bytes per second)
                        $uploadRate = if ($seconds -gt 0) { $sentBytes / $seconds } else { 0 }
                        $downloadRate = if ($seconds -gt 0) { $receivedBytes / $seconds } else { 0 }
                        
                        # Convert to bits per second for standard networking rates
                        $uploadRateBps = $uploadRate * 8
                        $downloadRateBps = $downloadRate * 8
                        
                        Write-Host "`n Bandwidth Usage for $($adapter.Name):" -ForegroundColor White
                        Write-Host "   Link Speed: $($adapter.LinkSpeed)" -ForegroundColor Cyan
                        
                        Write-Host "`n Current Rates:" -ForegroundColor Yellow
                        Write-Host "   Download: $(Format-NetworkSpeed $downloadRateBps)" -ForegroundColor Cyan
                        Write-Host "   Upload: $(Format-NetworkSpeed $uploadRateBps)" -ForegroundColor Cyan
                        
                        Write-Host "`n Total Data Transferred:" -ForegroundColor Yellow
                        Write-Host "   Downloaded: $(Format-ByteSize $currentStats.ReceivedBytes)" -ForegroundColor Cyan
                        Write-Host "   Uploaded: $(Format-ByteSize $currentStats.SentBytes)" -ForegroundColor Cyan
                        
                        # Calculate and show usage ratios
                        if ($currentStats.SentBytes -gt 0 -and $currentStats.ReceivedBytes -gt 0) {
                            $ratio = [math]::Round($currentStats.ReceivedBytes / $currentStats.SentBytes, 2)
                            Write-Host "`n Usage Analysis:" -ForegroundColor Yellow
                            Write-Host "   Download/Upload Ratio: $ratio" -ForegroundColor Cyan
                            
                            # Give a simple description of the network usage pattern
                            if ($ratio -gt 5) {
                                Write-Host "   Usage Pattern: Primarily download-heavy usage" -ForegroundColor Cyan
                            } elseif ($ratio -lt 0.2) {
                                Write-Host "   Usage Pattern: Primarily upload-heavy usage" -ForegroundColor Cyan
                            } else {
                                Write-Host "   Usage Pattern: Balanced upload and download usage" -ForegroundColor Cyan
                            }
                        }
                    }
                    
                    # Offer to do continuous monitoring
                    Write-Host "`n Would you like to monitor bandwidth continuously for 30 seconds? (Y/N)" -ForegroundColor Yellow
                    $response = Read-Host " ► "
                    
                    if ($response -eq "Y" -or $response -eq "y") {
                        # Select an adapter if multiple are available
                        $selectedAdapter = $adapters
                        if ($adapters.Count -gt 1) {
                            Write-Host "`n Select an adapter to monitor:" -ForegroundColor Yellow
                            for ($i = 0; $i -lt $adapters.Count; $i++) {
                                Write-Host " [$i] $($adapters[$i].Name)" -ForegroundColor Cyan
                            }
                            
                            $adapterIdx = Read-Host " ► "
                            if ([int]::TryParse($adapterIdx, [ref]$null) -and [int]$adapterIdx -ge 0 -and [int]$adapterIdx -lt $adapters.Count) {
                                $selectedAdapter = $adapters[[int]$adapterIdx]
                            } else {
                                $selectedAdapter = $adapters[0]
                                Write-Host " Invalid selection. Using $($selectedAdapter.Name)." -ForegroundColor Yellow
                            }
                        } else {
                            $selectedAdapter = $adapters[0]
                        }
                        
                        Write-Host "`n Monitoring bandwidth for $($selectedAdapter.Name) over 30 seconds..." -ForegroundColor Yellow
                        $initialReading = Get-NetAdapterStatistics -Name $selectedAdapter.Name
                        $startTime = Get-Date
                        
                        for ($i = 1; $i -le 10; $i++) {
                            Start-Sleep -Seconds 3
                            $currentReading = Get-NetAdapterStatistics -Name $selectedAdapter.Name
                            
                            # Calculate rates since last reading
                            $timeElapsed = ((Get-Date) - $startTime).TotalSeconds
                            
                            $totalDownloaded = $currentReading.ReceivedBytes - $initialReading.ReceivedBytes
                            $totalUploaded = $currentReading.SentBytes - $initialReading.SentBytes
                            
                            $downloadRate = if ($timeElapsed -gt 0) { ($totalDownloaded / $timeElapsed) * 8 } else { 0 }
                            $uploadRate = if ($timeElapsed -gt 0) { ($totalUploaded / $timeElapsed) * 8 } else { 0 }
                            
                            Write-Host " [$i/10] Download: $(Format-NetworkSpeed $downloadRate) | Upload: $(Format-NetworkSpeed $uploadRate)" -ForegroundColor Cyan
                        }
                        
                        # Show summary
                        $finalReading = Get-NetAdapterStatistics -Name $selectedAdapter.Name
                        $totalTime = ((Get-Date) - $startTime).TotalSeconds
                        $totalDownloaded = $finalReading.ReceivedBytes - $initialReading.ReceivedBytes
                        $totalUploaded = $finalReading.SentBytes - $initialReading.SentBytes
                        
                        Write-Host "`n Monitoring Summary:" -ForegroundColor Yellow
                        Write-Host "   Duration: $([Math]::Round($totalTime, 1)) seconds" -ForegroundColor Cyan
                        Write-Host "   Total Downloaded: $(Format-ByteSize $totalDownloaded)" -ForegroundColor Cyan
                        Write-Host "   Total Uploaded: $(Format-ByteSize $totalUploaded)" -ForegroundColor Cyan
                        Write-Host "   Average Download Rate: $(Format-NetworkSpeed (($totalDownloaded / $totalTime) * 8))" -ForegroundColor Cyan
                        Write-Host "   Average Upload Rate: $(Format-NetworkSpeed (($totalUploaded / $totalTime) * 8))" -ForegroundColor Cyan
                    }
                } catch {
                    Write-Error-Message "Error analyzing bandwidth usage" $_
                }
            }
            Perform-NetworkAction -Title $title -Action $action
        }
        "4" {
            # Network Performance Statistics (keep as is)
            $title = "Network Performance Statistics"
            $action = { Display-AdapterStatistics }
            Perform-NetworkAction -Title $title -Action $action
        }
        "5" {
            Clear-Host

            # Start Continuous Monitoring
            $title = "Continuous Network Monitoring"
            $action = {
                $duration = Read-Host " ► Enter duration in seconds (e.g., 60)"
                $interval = Read-Host " ► Enter interval in seconds (e.g., 5)"
                
                if (-not ([int]::TryParse($duration, [ref]$null)) -or [int]$duration -le 0) {
                    Write-Host " Invalid duration. Using default of 60 seconds." -ForegroundColor Yellow
                    $duration = 60
                }
                
                if (-not ([int]::TryParse($interval, [ref]$null)) -or [int]$interval -le 0) {
                    Write-Host " Invalid interval. Using default of 5 seconds." -ForegroundColor Yellow
                    $interval = 5
                }
                
                try {
                    $endTime = (Get-Date).AddSeconds($duration)
                    $iteration = 1
                    
                    # Store initial statistics for comparison
                    $previousStats = @{}
                    $initialStats = Get-NetAdapterStatistics
                    foreach ($adapter in $initialStats) {
                        $previousStats[$adapter.Name] = @{
                            SentBytes = $adapter.SentBytes
                            ReceivedBytes = $adapter.ReceivedBytes
                        }
                    }
                    
                    while ((Get-Date) -lt $endTime) {
                        Clear-Host
                        Write-Host "`n Continuous Monitoring (Iteration $iteration)" -ForegroundColor Green
                        Write-Host " Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
                        Write-Host " ------------------------------" -ForegroundColor Green
                        
                        $currentStats = Get-NetAdapterStatistics
                        foreach ($adapter in $currentStats) {
                            # Calculate data transferred since last check
                            $sentDiff = 0
                            $receivedDiff = 0
                            
                            if ($previousStats.ContainsKey($adapter.Name)) {
                                $sentDiff = $adapter.SentBytes - $previousStats[$adapter.Name].SentBytes
                                $receivedDiff = $adapter.ReceivedBytes - $previousStats[$adapter.Name].ReceivedBytes
                            }
                            
                            # Update previous stats for next iteration
                            $previousStats[$adapter.Name] = @{
                                SentBytes = $adapter.SentBytes
                                ReceivedBytes = $adapter.ReceivedBytes
                            }
                            
                            # Format the byte counts for better readability
                            $sentFormatted = Format-ByteSize $adapter.SentBytes
                            $receivedFormatted = Format-ByteSize $adapter.ReceivedBytes
                            $sentDiffFormatted = Format-ByteSize $sentDiff
                            $receivedDiffFormatted = Format-ByteSize $receivedDiff
                            
                            Write-Host " $($adapter.Name):" -ForegroundColor White
                            Write-Host "   Total: Sent: $sentFormatted, Received: $receivedFormatted" -ForegroundColor Cyan
                            Write-Host "   Last ${interval}s: Sent: $sentDiffFormatted, Received: $receivedDiffFormatted" -ForegroundColor Yellow
                        }
                        
                        $remainingTime = ($endTime - (Get-Date)).TotalSeconds
                        Write-Host "`n Monitoring will continue for approximately $([Math]::Ceiling($remainingTime)) more seconds..." -ForegroundColor Magenta
                        
                        $iteration++
                        Start-Sleep -Seconds $interval
                    }
                } catch {
                    Write-Error-Message "Error during continuous monitoring" $_
                }
            }
            Perform-NetworkAction -Title $title -Action $action
        }
        "6" {
            Clear-Host

            # View Connection Statistics
            $title = "Connection Statistics"
            $action = {
                try {
                    # First, let the user select a network interface
                    $interfaces = Get-NetAdapter | Where-Object Status -eq "Up"
                    
                    if ($interfaces.Count -eq 0) {
                        Write-Host " No active network interfaces found." -ForegroundColor Yellow
                        return
                    }
                    
                    Write-Host "`n Available Network Interfaces:" -ForegroundColor Yellow
                    for ($i = 0; $i -lt $interfaces.Count; $i++) {
                        Write-Host " [$i] $($interfaces[$i].Name) - $($interfaces[$i].InterfaceDescription)" -ForegroundColor Cyan
                    }
                    
                    $selectedIdx = Read-Host "`n ► Select interface by number"
                    
                    if (-not ([int]::TryParse($selectedIdx, [ref]$null)) -or [int]$selectedIdx -lt 0 -or [int]$selectedIdx -ge $interfaces.Count) {
                        Write-Host " Invalid selection. Using the first available interface." -ForegroundColor Yellow
                        $selectedIdx = 0
                    }
                    
                    $selectedInterface = $interfaces[$selectedIdx]
                    
                    # Now get the statistics for the selected interface
                    $stats = Get-NetAdapterStatistics -Name $selectedInterface.Name -ErrorAction Stop
                    $adapterInfo = $selectedInterface
                    
                    Write-Host "`n Interface Information:" -ForegroundColor Yellow
                    Write-Host "   Name: $($adapterInfo.Name)" -ForegroundColor Cyan
                    Write-Host "   Description: $($adapterInfo.InterfaceDescription)" -ForegroundColor Cyan
                    Write-Host "   Status: $($adapterInfo.Status)" -ForegroundColor Cyan
                    Write-Host "   Link Speed: $($adapterInfo.LinkSpeed)" -ForegroundColor Cyan
                    Write-Host "   MAC Address: $($adapterInfo.MacAddress)" -ForegroundColor Cyan
                    
                    Write-Host "`n Traffic Statistics:" -ForegroundColor Yellow
                    Write-Host "   Sent: $(Format-ByteSize $stats.SentBytes) (Total: $($stats.SentPackets) packets)" -ForegroundColor Cyan
                    Write-Host "   Received: $(Format-ByteSize $stats.ReceivedBytes) (Total: $($stats.ReceivedPackets) packets)" -ForegroundColor Cyan
                    
                    # Calculate ratio
                    if ($stats.SentBytes -gt 0 -and $stats.ReceivedBytes -gt 0) {
                        $ratio = [math]::Round($stats.ReceivedBytes / $stats.SentBytes, 2)
                        Write-Host "   Download/Upload Ratio: $ratio" -ForegroundColor Cyan
                    }
                    
                    Write-Host "`n Error Statistics:" -ForegroundColor Yellow
                    Write-Host "   Send Errors: $($stats.SentPacketsDiscarded) packets discarded" -ForegroundColor Cyan
                    Write-Host "   Receive Errors: $($stats.ReceivedPacketsDiscarded) packets discarded" -ForegroundColor Cyan
                    
                    # Get current TCP connections
                    Write-Host "`n Current TCP Connections:" -ForegroundColor Yellow
                    $connections = Get-NetTCPConnection | Where-Object { $_.LocalAddress -notlike "*:*" -and $_.State -eq "Established" } | 
                                   Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).Name}} |
                                   Sort-Object LocalPort | Select-Object -First 10
                    
                    if ($connections.Count -gt 0) {
                        $connections | Format-Table -AutoSize | Out-Host
                    } else {
                        Write-Host "   No established TCP connections found." -ForegroundColor Cyan
                    }
                    
                    # Live monitoring option
                    Write-Host "`n Would you like to monitor network activity for 10 seconds? (Y/N)" -ForegroundColor Yellow
                    $monitor = Read-Host " ► "
                    
                    if ($monitor -eq "Y" -or $monitor -eq "y") {
                        Write-Host "`n Monitoring network activity for 10 seconds..." -ForegroundColor Cyan
                        $startStats = Get-NetAdapterStatistics -Name $selectedInterface.Name
                        
                        for ($i = 1; $i -le 10; $i++) {
                            Start-Sleep -Seconds 1
                            $currentStats = Get-NetAdapterStatistics -Name $selectedInterface.Name
                            
                            $rxDelta = $currentStats.ReceivedBytes - $startStats.ReceivedBytes
                            $txDelta = $currentStats.SentBytes - $startStats.SentBytes
                            
                            $rxRate = [math]::Round($rxDelta / 1024 / 1024 * 8, 2)  # Mbps
                            $txRate = [math]::Round($txDelta / 1024 / 1024 * 8, 2)  # Mbps
                            
                            Write-Host "   Second $i - Download: $rxRate Mbps, Upload: $txRate Mbps" -ForegroundColor Cyan
                            $startStats = $currentStats
                        }
                    }
                } catch {
                    Write-Error-Message "Could not retrieve connection statistics" $_
                }
            }
            Perform-NetworkAction -Title $title -Action $action
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

# Helper Functions
function Perform-NetworkAction {
    param (
        [string]$Title,
        [scriptblock]$Action
    )
    
    Clear-Host
    Write-Host "`n $Title " -ForegroundColor Green
    Write-Host " $(('-' * $Title.Length))" -ForegroundColor Green
    
    & $Action
    
    Read-Host "`n Press Enter to continue"
    Monitor-Network
}

function Display-AdapterStatistics {
    try {
        $adapters = Get-NetAdapterStatistics
        if ($adapters.Count -eq 0) {
            Write-Host " No network adapters found." -ForegroundColor Yellow
            return
        }
        
        foreach ($adapter in $adapters) {
            $sentFormatted = Format-ByteSize $adapter.SentBytes
            $receivedFormatted = Format-ByteSize $adapter.ReceivedBytes
            
            Write-Host " $($adapter.Name):" -ForegroundColor White
            Write-Host "   Sent: $sentFormatted" -ForegroundColor Cyan
            Write-Host "   Received: $receivedFormatted" -ForegroundColor Cyan
        }
    } catch {
        Write-Error-Message "Error retrieving adapter statistics" $_
    }
}

function Write-Error-Message {
    param (
        [string]$Message,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    Write-Host " [-] $Message`: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
    Write-Host " Error occurred at: $($ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red
}

function Format-ByteSize {
    param ([long]$Bytes)
    
    if ($Bytes -ge 1TB) { 
        return "{0:N2} TB" -f ($Bytes / 1TB) 
    } elseif ($Bytes -ge 1GB) { 
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) { 
        return "{0:N2} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) { 
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } else { 
        return "$Bytes bytes"
    }
}

function Format-NetworkSpeed {
    param ([double]$BitsPerSecond)
    
    if ($BitsPerSecond -ge 1000000000) { # Gbps
        return "{0:N2} Gbps" -f ($BitsPerSecond / 1000000000)
    } elseif ($BitsPerSecond -ge 1000000) { # Mbps
        return "{0:N2} Mbps" -f ($BitsPerSecond / 1000000)
    } elseif ($BitsPerSecond -ge 1000) { # Kbps
        return "{0:N2} Kbps" -f ($BitsPerSecond / 1000)
    } else { # bps
        return "{0:N0} bps" -f $BitsPerSecond
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

        Write-Host "`n Exiting the script. Goodbye! Ahbibena ☻ <3" -ForegroundColor Red
        Start-Sleep -Seconds 2
        start https://github.com/j0oyboy
        clear-host
        break
    }
}