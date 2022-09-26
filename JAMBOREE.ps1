<# 
TODO:
* somehow auto accespt all licences or get all licence hashes and create them ?
* Clean/wipe install/cache 
* actualy download latest cmdline tools

PRECHECK/REQUIREMENTS:
* Intel for HAXM
* Hyperv disabled
* Enabled Xesst in BIOS

CLEANUP:
rd q/s "c:\Python310\"
rd q/s "c:\Users\internet\.gradle"
rd q/s "c:\Users\internet\AndroidStudioProjects"
rd q/s "c:\Users\internet\AppData\Local\Android"
rd q/s "c:\Users\internet\AppData\Local\Google"

-RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt

#>

# set current directory
$VARCD = (Get-Location)
Write-Host "[+] Current Working Directory $VARCD"
Set-Location -Path "$VARCD"

# env 
$env:ANDROID_SDK_ROOT="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD"
$env:ANDROID_HOME="$VARCD"
$env:ANDROID_AVD_HOME="$VARCD\avd"
New-Item -Path "$VARCD\avd" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
$env:ANDROID_SDK_HOME="$VARCD"

$env:JAVA_HOME = "$VARCD\jdk-11.0.1"
$env:Path = "$env:Path;$VARCD\platform-tools\"

# Setup Form
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.AutoSize = $true
$main_form.Text = "JAMBOREE"

$hShift = 0
$vShift = 0


### MAIN ###

################################# FUNCTIONS


############# downloadFile
function downloadFile($url, $targetFile)
{
    "Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        #[System.Console]::CursorLeft = 0
        [System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    "Finished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}


############# CHECK JAVA
Function CheckJava {
   if (-not(Test-Path -Path "$VARCD\jdk-11.0.1" )) { 
        try {
            Write-Host "[+] Downloading Java"
            downloadFile "https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_windows-x64_bin.zip" "$VARCD\openjdk.zip"
            Write-Host "[+] Extracting Java"
            Expand-Archive -Path  "$VARCD\openjdk.zip" -DestinationPath "$VARCD" -Force
            $env:JAVA_HOME = "$VARCD\jdk-11.0.1"
            $env:Path = "$VARCD\jdk-11.0.1;$env:Path"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\openjdk.zip already exists"
            }
}




################################# FUNCTIONS END
function CheckADB {
    $varadb = (adb devices)
    Write-Host "[+] $varadb"
    $varadb = $varadb -match 'device\b' -replace 'device',''
    Write-Host "[+] Online Device is: $varadb"
        if (($varadb.length -lt 1 )) {
            Write-Host "[+] ADB Failed"
            [void][System.Windows.MessageBox]::Show("ADB Failed. Wait and try again","Error")
        }
    return $varadb
}

############# BUTTON1
$Button1 = New-Object System.Windows.Forms.Button
$Button1.AutoSize = $true
$Button1.Text = "ADB Shell"
$Button1.Location = New-Object System.Drawing.Point(($hShift),($vShift+0))
$Button1.Add_Click({Button1})
$main_form.Controls.Add($Button1)

Function Button1 {
    $varadb=CheckADB
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  "-s $varadb shell " -Wait  
}

############# BUTTON2
$Button2 = New-Object System.Windows.Forms.Button
$Button2.AutoSize = $true
$Button2.Text = "AVD Download/Install"
$Button2.Location = New-Object System.Drawing.Point(($hShift),($vShift+30))
$Button2.Add_Click({Button2})
$main_form.Controls.Add($Button2)

Function Button2 {
    if (-not(Test-Path -Path "$VARCD\cmdline-tools" )) {
        try {
            Write-Host "[+] Downloading Android Command Line Tools"
            downloadFile "https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip" "$VARCD\commandlinetools-win.zip"
            Write-Host "[+] Extracting AVD"
            Expand-Archive -Path  "$VARCD\commandlinetools-win.zip" -DestinationPath "$VARCD" -Force 
            Write-Host "[+] Setting path to latest that AVD wants ..."
            Rename-Item -Path "$VARCD\cmdline-tools" -NewName "$VARCD\latest"
            New-Item -Path "$VARCD\cmdline-tools" -ItemType Directory
            Move-Item "$VARCD\latest" "$VARCD\cmdline-tools\"
            }
                catch {
                    throw $_.Exception.Message
            }
            }
        else {
            Write-Host "[+] $VARCD\commandlinetools-win.zip already exists"
            }
  
    
    CheckJava
    Write-Host "[+] Creating licenses Files"
    $licenseContentBase64 = "UEsDBBQAAAAAAKNK11IAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKBK11LzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAKFK11IKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACiStdSec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACiStdSk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACiStdSrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACjStdSkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAAo0rXUgAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYACIHOBcRaNcBIgc4FxFo1wHBTVQTEWjXAVBLAQI/AAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGACUEFUTEWjXAZQQVRMRaNcB6XRUExFo1wFQSwECPwAKAAAAAACgStdS80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgAsEM0FBFo1wGwQzQUEWjXAXb1MxQRaNcBUEsBAj8ACgAAAAAAoUrXUgpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGAAsMGUVEWjXASwwZRURaNcB5whlFRFo1wFQSwECPwAKAAAAAACiStdSec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgA7s3WFRFo1wHuzdYVEWjXAfGm1hURaNcBUEsBAj8ACgAAAAAAokrXUpOr0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAGRDRxYRaNcBZENHFhFo1wFfHEcWEWjXAVBLAQI/AAoAAAAAAKJK11KsTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADGsq0WEWjXAcayrRYRaNcBxrKtFhFo1wFQSwECPwAKAAAAAACjStdSkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA4LjgXEWjXATguOBcRaNcBIgc4FxFo1wFQSwUGAAAAAAgACACDAwAACQMAAAAA"
    $licenseContent = [System.Convert]::FromBase64String($licenseContentBase64)
    Set-Content -Path "$VARCD\android-sdk-licenses.zip" -Value $licenseContent -Encoding Byte
    Expand-Archive  "$VARCD\android-sdk-licenses.zip"  -DestinationPath "$VARCD\"  -Force
    Write-Host "[+] Running sdkmanager/Installing"
    

   
    

    # now we are using latest cmdline-tools ...!?
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platform-tools" -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "extras;intel;Hardware_Accelerated_Execution_Manager" -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "platforms;android-30" -Verbose 
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "emulator" -Verbose
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\sdkmanager.bat" -ArgumentList  "system-images;android-30;google_apis_playstore;x86" -Verbose
    Write-Host "[+] Wait for AVD Install to Complete"
    }
    
############# BUTTON3
$Button3 = New-Object System.Windows.Forms.Button
$Button3.AutoSize = $true
$Button3.Text = "Create AVD"
$Button3.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+60))
$Button3.Add_Click({Button3})
$main_form.Controls.Add($Button3)

Function Button3 {
    Start-Process -FilePath "$VARCD\cmdline-tools\latest\bin\avdmanager.bat" -ArgumentList  "create avd -n pixel_2 -k `"system-images;android-30;google_apis_playstore;x86`"  -d `"pixel_2`" --force" -Wait   -Verbose  -RedirectStandardError error.txt -RedirectStandardOutput output.txt
    Get-Content "$VARCD\error.txt"
    Get-Content "$VARCD\output.txt"
}

############# BUTTON4
$Button4 = New-Object System.Windows.Forms.Button
$Button4.AutoSize = $true
$Button4.Text = "Start AVD -writable-system"
$Button4.Location = New-Object System.Drawing.Point(($hShift+0),($vShift+90))
$Button4.Add_Click({Button4})
$main_form.Controls.Add($Button4)

Function Button4 {
    Write-Host "[+] Starting AVD emulator"
    Start-Process -FilePath "$VARCD\emulator\emulator.exe" -ArgumentList  " -avd pixel_2 -writable-system"  -WindowStyle Minimized
}

############# BUTTON5
$Button5 = New-Object System.Windows.Forms.Button
$Button5.AutoSize = $true
$Button5.Text = "ADB Poweroff"
$Button5.Location = New-Object System.Drawing.Point(($hShift),($vShift+120))
$Button5.Add_Click({Button5})
$main_form.Controls.Add($Button5)

Function Button5 {
    $varadb=CheckADB
    Start-Process -FilePath "$VARCD\platform-tools\adb.exe" -ArgumentList  "-s $varadb shell -t  `"reboot -p`"" -Wait
}

############# Button6
$Button6 = New-Object System.Windows.Forms.Button
$Button6.AutoSize = $true
$Button6.Text = "rootAVD/Install Magisk"
$Button6.Location = New-Object System.Drawing.Point(($hShift),($vShift+150))
$Button6.Add_Click({Button6})
$main_form.Controls.Add($Button6)

Function Button6 {
if (-not(Test-Path -Path "$VARCD\rootAVD-master" )) {
    try {
            Write-Host "[+] Downloading rootAVD"
            downloadFile "https://github.com/newbit1/rootAVD/archive/refs/heads/master.zip" "$VARCD\rootAVD-master.zip"
            Write-Host "[+] Extracting rootAVD (Turn On AVD 1st" 
            Expand-Archive -Path  "$VARCD\rootAVD-master.zip" -DestinationPath "$VARCD" -Force
        }
            catch {
            throw $_.Exception.Message
            }
        }
        else {
            Write-Host "[+] $VARCD\rootAVD-master already exists"
        }
    
    Set-Location -Path "$VARCD\rootAVD-master"
    $varadb=CheckADB   
    Write-Host "[+] Running installing magisk via rootAVD to ramdisk.img"
    Start-Process -FilePath "$VARCD\rootAVD-master\rootAVD.bat" -ArgumentList  "$VARCD\system-images\android-30\google_apis_playstore\x86\ramdisk.img" -Wait 
    Write-Host "[+] rootAVD Finished if the emulator did not close/poweroff try again"
    
}
 
<#
Shell Notes:

cd  C:\JAMBOREE
set ANDROID_SDK_ROOT=%CD%
set ANDROID_AVD_HOME=%CD%
set ANDROID_HOME=%CD%
set ANDROID_AVD_HOME=%CD%\avd
set ANDROID_SDK_HOME=%CD%
set JAVA_HOME=%CD%\jdk-11.0.1
set PATH=%CD%\platform-tools\;%Path%
cd  rootAVD-master
rootAVD.bat "C:\JAMBOREE\system-images\android-30\google_apis_playstore\x86\ramdisk.img"
#>


############# SHOW FORM
$main_form.ShowDialog()