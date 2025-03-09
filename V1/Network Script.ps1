chcp 65001 > $null
# Change Window Size
[console]::SetWindowSize(120, 22)

# Change the Windows Name
$host.UI.RawUI.WindowTitle = "Network Tool"

#Function
function Center-text ($text){
    $width = [console]::WindowWidth
    $padLef = [math]::Max(0,($width - $text.Length)) / 2
    return (' ' * $padLef) + $text
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
    "                                                                                                  by Souhaib ",
    " "
)

$menu = @(
    " ",
    "╔═════════════════════════════════════════╗"
    "║ 1. Get Interface Information            ║",
    "║ 2. Configure a Static IP Address        ║",
    "║ 3. Configure a DHCP IP Address          ║",
    "║ 4. Change to DHCP IP                    ║",
    "║ 5. Exit the script                      ║",
    "╚═════════════════════════════════════════╝",
    " "
)

$choice1 = @(
    " ",
    "╔═══════════════════════════════╗",
    "║ 1. Interface Description      ║",
    "║ 2. MAC Address                ║",
    "║ 3. Interface Status           ║",
    "║ 4. Link Speed                 ║",
    "║ 0. Return to Main Menu        ║",
    "╚═══════════════════════════════╝"
)

$choice2 = @(
        " ",
    "╔═══════════════════════════════╗",
    "║ 1. Configure the interface    ║",
    "║ 2. Verification               ║",
    "║ 3. Print IP after change      ║",
    "║ 0. Return To the Main Menu    ║",
    "╚═══════════════════════════════╝"
)

while ($true){
    clear
    foreach($line in $Banner){ Write-Host (Center-text $line) -ForegroundColor Red}
    foreach($line in $menu){ Write-Host (Center-text $line) -ForegroundColor Yellow}
    
    $choice = Read-Host " ♥ Enter your Choice "

    switch($choice){
        "1"{
            clear
            Write-Host "`n Getting the INTERFACE Information..."
            Start-Sleep 1
            clear   

            clear
            Write-Host "`n 🗹 Available Interfaces in your Machine:" -ForegroundColor Cyan

            # Liste et affiche toutes les interfaces disponibles
            $AvInt = Get-NetAdapter | Select-Object Name
            $AvInt | ForEach-Object { Write-Host " ➤ $($_.Name)" -ForegroundColor Yellow }                   

            
            while ($true) {
                $ReturnMenu = Read-Host "`n Enter '0' to return to Main Menu, Or '1' to continue"
    
                if ($ReturnMenu -eq "0") {
                    break
                } elseif ($ReturnMenu -eq "1") {
                    continue
                } else {
                    Write-Host "Invalid input. Please enter 0 or 1." -ForegroundColor Red
                    # The loop will continue, prompting the user again
                }
            }

            # Vérification de l'entrée utilisateur avec option de retour au menu
            while ($true) {
               
                $IntName = Read-Host "`n ► Enter the INTERFACE name (as shown above)"                
                $interface = Get-NetAdapter -Name $IntName -ErrorAction SilentlyContinue

                if ($interface) {
                    break  # L'interface est valide, on sort de la boucle
                }

                # Interface invalide, proposer de réessayer ou retourner au menu
                Write-Host "`n [-] Interface '$IntName' not found! Do you want to retry? (Y/N)" -ForegroundColor Red
                $retry = Read-Host "`n Enter Y to retry, N to return to the main menu"

                if ($retry -match "[Nn]") { 
                    return  # Retourne au menu principal
                }
            }

            $subMenu2 = $true
            while ($subMenu2) {  # Boucle interne pour rester dans le sous-menu
                clear
                [console]::SetWindowSize(67, 15)
                $host.UI.RawUI.WindowTitle = "INREFACE Description"
                foreach($line in $choice1){ Write-Host (Center-text $line) -ForegroundColor Cyan}
                
                $OptionChoice1 = Read-Host "`n ♀ Choose an option"

                switch ($OptionChoice1) {
                    "1" {
                        clear
                        $IntDes = (Get-NetAdapter -Name "$IntName").InterfaceDescription
                        Write-Host " Interface '$IntName' Description: $IntDes" -ForegroundColor Green                                
                        Start-Sleep 2
                    }
                    "2" {
                        clear
                        $MacAdd = (Get-NetAdapter -Name "$IntName").MacAddress
                        Write-Host " Interface '$IntName' MAC Address: $MacAdd" -ForegroundColor Green
                        Start-Sleep 2
                    }
                    "3" {
                        clear
                        $Status = (Get-NetAdapter -Name "$IntName").Status
                        Write-Host " Interface '$IntName' Status: $Status" -ForegroundColor Green
                        Start-Sleep 2
                    }
                    "4" {
                        clear
                        $Speed = (Get-NetAdapter -Name "$IntName").LinkSpeed
                        Write-Host " Interface '$IntName' Link Speed: $Speed" -ForegroundColor Green
                        Start-Sleep 2
                    }
                    "0" {
                        $subMenu2 = $false
                    }
                    default {
                        Write-Host "`n Invalid option, please try again." -ForegroundColor Red
                        Start-Sleep 2
                    }
                }
            }

            [console]::SetWindowSize(120, 22) # Remettre la taille normale du terminal
        }

        "2"{
            clear            
            Write-Host "`n ☻ Configuring the interface..." -ForegroundColor Yellow
            start-sleep 2

            $subMenu = $true                                   
            while($true){
            clear
                [console]::SetWindowSize(75, 12)
                $host.UI.RawUI.WindowTitle = ("Configuring the IP")
                foreach ($line in $choice2) { Write-Host (Center-text $line) -ForegroundColor Cyan }              
                

                $OptionChoice2 = Read-Host "`n ♀ Choose an option "

                Switch($OptionChoice2){
                    "1"{
                        clear
                        $int = Read-Host "`n ☺ Enter the interface you wanna change their ip address "
                        $IPadd = Read-Host "`n ☺ Enter the IP Address for this interface "
                        $Gat = Read-Host "`n ☺ Enter the Gateway Address "
                        $Dns = Read-Host "`n ☺ Enter the DNS server IP"

                        try {
                            New-NetIPAddress -InterfaceAlias $int -IPAddress $IPadd -DefaultGateway $Gat -ErrorAction Stop
                            Write-Host "`n IP address configured successfully!" -ForegroundColor Green
                        } catch {
                            Write-Host "`n Failed to configure IP address: $_" -ForegroundColor Red
                        }
                        start-sleep 2
                    }
                    "2"{
                        clear
                        Write-Host "`n Checking the IP if he change..."
                        $configuredIP = Get-NetIPAddress -InterfaceAlias $int -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
                        if ($configuredIP -eq $IPadd) {
                            Write-Host "`n IP address verified successfully!" -ForegroundColor Green
                        } else {
                            Write-Host "`n IP address verification failed." -ForegroundColor Red
                        }
                        Start-Sleep 2
                    }
                    "3"{
                        clear
                        $intConf = Read-Host "`n Enter the Interface you wanna know their IP "
                        $IP4 = (Get-NetIPAddress -InterfaceAlias $intConf | Where-Object { $_.AddressFamily -eq "IPv4" }).IPAddress
                        $IP6 = (Get-NetIPAddress -InterfaceAlias $intConf | Where-Object { $_.AddressFamily -eq "IPv6" }).IPAddress
                        
                        Write-Host "`n IP4: '$IP4'`n" -ForegroundColor Green
                        Write-Host " IP6: '$IP6'" -ForegroundColor Cyan
                        Start-Sleep 2
                    }
                    "0"{
                        $subMenu = $false
                        continue
                    }    
                    default {
                        Write-Host "`n Invalid option, please try again." -ForegroundColor Red
                        Start-Sleep 2
                    
                    }
                } 
             }               
        }

        "3"{
            clear
            Write-Host "`n 3"
            Start-Sleep 2
        }

        "4"{
            clear
            Write-Host "`n 3"
            Start-Sleep 2
        }

        "5"{
            clear
            Write-Host "`n Exiting the script..." -ForegroundColor Red
            Start-Sleep 2
            exit            
        }

        default {
            Write-Host " Invalid option, please try again." -ForegroundColor Red
            Start-Sleep 2
        }
    }
}