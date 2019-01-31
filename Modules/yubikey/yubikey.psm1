Function Test-PivToolEnable(){
    Get-Command yubico-piv-tool -ea SilentlyContinue | Out-Null
    if ($? -eq $true) {
        return $true
    }
    return $false 
}

Function TryErrorCommand([string]$command, [string]$options){
    if(-Not $command){
        Write-Error "invalid argument for TryErrorCommand \ncommand should not be null or empty"
        return
    }
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $command
    $processInfo.RedirectStandardError = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute = $false
    $processInfo.Arguments = $options
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $processInfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    return $stderr
}

Function BlockPIN(){
    $result = TryErrorCommand "yubico-piv-tool" "-averify-pin -P471112"
    $retryCount = 0

    while($result -match "tries left"){
        $result = TryErrorCommand "yubico-piv-tool" "-averify-pin -P471112"
        $retryCount ++
        if($retryCount -gt 255){
            Write-Error "BlockPIN falid too many retries"
            return 
        }
    }
    Write-Host $result
    return 
}

#
# see https://gist.github.com/1940fec5e9cdffb30c01e18e38ff4532.git
#

Function BlockPUK(){
    $result = TryErrorCommand "yubico-piv-tool" "-a change-puk -P471112 -N6756789"
    $retryCount = 0

    while($result -match "tries left"){
        $result = TryErrorCommand "yubico-piv-tool" "-a change-puk -P471112 -N6756789"
        $retryCount ++
        if($retryCount -gt 255){
            Write-Error "BlockPUK falid too many retries"
            return 
        }
    }

    Write-Host $result
    return
}

Function CheckPIVToolInstalledIfNotTryAddPath(){
    $PIV_TOOL_BINFILE = Join-Path ${Env:ProgramFiles(x86)} "Yubico\YubiKey PIV Manager"
    if( -Not (Test-PivToolEnable) ){
        if( -Not (Test-Path $PIV_TOOL_BINFILE) ){
            Write-Host This scripts are required yubico-piv-tool or yubikey-piv-manager
            Write-Host https://developers.yubico.com/yubico-piv-tool/
            Write-Host https://developers.yubico.com/yubikey-piv-manager/
            
            Write-Error "yubico-piv-tool not found"

            return
        }
        $Env:Path += ";" + $PIV_TOOL_BINFILE
    }
    
    if( -Not (Test-PivToolEnable) ){
        Write-Error "unknown error in ResetYubiKey command"
        return
    }
    return $true
}

Function ResetYubiKey(){
    BlockPIN
    BlockPUK
    yubico-piv-tool -areset    
}

Function ChangePIN([string]$oldPIN, [string]$newPIN){
    try {
        yubico-piv-tool -achange-pin -P $oldPIN -N $newPIN        
    }
    catch {
        echo $error
    }
}

Function ChangePINIfFirstLogin(){
    $installedFile = "~\.pinHasChanged"
    if(Test-Path $installedFile){
        echo "pin already has changed"
        return
    }
    
    $newPIN
    while(-Not $newPIN){        
        $newPIN = UserInputNewPin
    }

    ChangePIN 123456 $newPIN

    # It's unsecure output PIN code to file system
    echo $newPIN | Out-File -Encoding "utf8" -PSPath $installedFile
}

Function UserInputNewPin(){
    $DEFAULT_PIN = 123456
    Write-Host "enter new PIN code"
    Write-Host "PIN code length is 6~8"

    # It's unsecure show pin in prompt
    # if hide input value, add -AsSecureString 
    # @see http://www.vwnet.jp/windows/PowerShell/InputSecretString.htm
    
    $newPIN = Read-Host "Enter New PIN"
    $newPINvery = Read-Host "Enter New PIN"

    if($newPIN -ne $newPINvery){
        Write-Host "verify failed please try again"
        return $false
    }

    if( ($newPIN.length -gt 8) -or ($newPIN.length -lt 6)){
        Write-Host "Pin length should be 6~8 please try again"
        return $false
    }

    if( $DEFAULT_PIN -eq $newPIN){
        Write-Host "PIN should be change from default value please try again"
        return $false
    }

    #add any pin code check
 
    return $newPIN
}

Export-ModuleMember -Function *