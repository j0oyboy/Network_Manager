# Network Tool Advanced Edition

![image](https://github.com/user-attachments/assets/c9eeab0f-09f9-4525-85f7-5706d150f7e1)

## Overview

Network Tool Advanced Edition is a comprehensive PowerShell-based network management and diagnostics utility designed to simplify network configuration and troubleshooting tasks. This tool provides system administrators and network professionals with a user-friendly interface to manage all aspects of network connectivity on Windows systems.

## Features

### 🌐 Network Interface Management

- View all network adapters on the system
- Get detailed interface information (description, MAC address, status, link speed)
- Configure interface properties and advanced settings

### 📡 IP Configuration

- Configure static IPv4 and IPv6 addresses
- Enable/disable DHCP
- Add additional IP addresses to interfaces
- Configure DNS servers
- View current configuration details

### 🔍 Network Diagnostics & Troubleshooting

- Run ping tests to verify connectivity
- Perform trace route analysis
- Execute DNS lookups
- Run network speed tests
- Check overall network connectivity
- Test port connectivity
- Generate comprehensive network diagnostics reports

### 💾 Network Profiles

- Save current network configurations as profiles
- Load saved network profiles
- Delete obsolete profiles
- View all saved configuration profiles

### 📶 Wi-Fi Management

- View available wireless networks
- Connect to Wi-Fi networks
- Disconnect from wireless connections
- Manage saved wireless networks
- Monitor Wi-Fi signal strength
- Create Wi-Fi hotspots

### 🔒 Firewall Management

- View current firewall status
- Enable or disable Windows Firewall
- Add custom firewall rules
- Remove firewall rules
- View active firewall rules

### 📊 Network Monitoring

- Monitor network traffic in real-time
- View active network connections
- Monitor bandwidth usage
- Display network performance statistics
- Perform continuous network monitoring
- View detailed connection statistics

## Requirements

- Windows 7/8/10/11 or Windows Server 2012 R2 or newer
- PowerShell 5.1 or higher
- Administrator privileges

## Installation

1. Clone this repository or download the script:
    
    ```
    git clone https://github.com/j0oyboy/https://github.com/j0oyboy/Network_Manager.git.git
    ```
    
2. Navigate to the script directory:
    
    ```
    cd Network_Manager
    ```
    
3. Run the script with administrator privileges:
    
    ```
    powershell -ExecutionPolicy Bypass -File "Network Manager - V2.ps1"
    ```
    

## Usage

1. Launch the script with administrator privileges
2. The main menu will display all available options
3. Select a network adapter to work with
4. Navigate through the menus to access the desired functionality

### Main Menu Options

1. **View Network Adapters** - Lists all available network interfaces
2. **Get Interface Information** - Shows detailed information about the selected interface
3. **Configure IP Address** - Allows setting static IP or enabling DHCP
4. **Network Diagnostics & Troubleshooting** - Tools for diagnosing network issues
5. **Network Profiles** - Save and load network configurations
6. **Wi-Fi Management** - Tools for managing wireless connections
7. **Firewall Management** - Options for configuring Windows Firewall
8. **Network Monitoring** - Tools for monitoring network performance
9. **Change Selected Interface** - Switch to a different network adapter
10. **Exit** - Close the application

## Screenshots
##### <center> Get Interface Information</center>
![image](https://github.com/user-attachments/assets/cd491945-5c98-4ef7-b913-18f9650f7932)

##### <center> Network Diagnostics & Troubleshooting</center>
![image](https://github.com/user-attachments/assets/e9583fc2-f6c3-44d5-81f1-a6c321e4ceed)


##### <center> Network Monitoring</center>
![image](https://github.com/user-attachments/assets/705a2dd4-8841-4634-95de-5bb02fb83b4c)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Created by Souhaib
- Special thanks to all contributors and testers
