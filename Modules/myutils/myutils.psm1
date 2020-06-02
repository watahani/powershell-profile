#
# Utilities by watahani
#

# Windows Path to Linux
function pwd_as_linux {
    "/$((pwd).Drive.Name.ToLowerInvariant())/$((pwd).Path.Replace('\', '/').Substring(3))"
}
# Calculate File-Hashes
function Get-File-Sha1Hashes {
    $files = Get-ChildItem -Force
    foreach ($file in $files) {
        if ($file.Extension -eq ".sha1") {
            continue
        }
        if (!$file.PSIsContainer) {
            $(Get-FileHash $file -Algorithm SHA1).Hash | Out-File -FilePath ($file.Name + ".sha1") -Encoding utf8
        }
    }
}

# Check Command Enable
function Test-Command-Enable {
    [OutputType([String])]
    param(
        [String]$command
    )
    process {
        Get-Command $command -ea SilentlyContinue | Out-Null
        if ($? -eq $true) { 
            return $true
        }
        return $false
    }
}
function Switch-AzureADModule {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet("AzureAD" , "AzureADPreview")]$version
    )
    $profilePath = $(Split-Path $PROFILE)
    $azureADModule = Get-Module -Name AzureADPreview
    if (-not $azureADModule) {
        $azureADModule = Get-Module -Name AzureAD
    }

    if ($azureADModule) {
        $currentVersion = $azureADModule.Name
        Write-Host "Remove-Module $currentVersion"
        Remove-Module -Name $currentVersion
        $selectedVersion = if ($currentVersion -eq "AzureAD") { Write-Output "AzureADPreview" }else { Write-Output "AzureAD" }
    }
    else {
        $selectedVersion = "AzureAD"
    }

    if ($version) {
        $selectedVersion = $version
    }

    switch ($selectedVersion) {
        "AzureAD" {
            $modulePath = Join-Path $profilePath "AzureAD"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "AzureAD.psd1"
        }
        "AzureADPreview" {
            $modulePath = Join-Path $profilePath "AzureADPreview"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "AzureADPreview.psd1"
        }
        Default { }
    }
    Write-Host "Import Module from $modulePath"
    Import-Module $modulePath -Global
}

function Switch-AzureResourceModule {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateSet("Az" , "AzureRM")]$version
    )
    $profilePath = $(Split-Path $PROFILE)
    $AzureResourceModule = Get-Module -Name AzureRM
    if (-not $AzureResourceModule) {
        $AzureResourceModule = Get-Module -Name Az
    }

    if ($AzureResourceModule) {
        $currentVersion = $AzureResourceModule.Name
        Write-Host "Remove-Module $currentVersion and $currentVersion.*"
        Remove-Module -Name $currentVersion
        Remove-Module -Name "$currentVersion.*"
        $selectedVersion = if ($currentVersion -eq "Az") { Write-Output "AzureRM" }else { Write-Output "Az" }
    }
    else {
        $selectedVersion = "Az"
    }

    if ($version) {
        $selectedVersion = $version
    }

    switch ($selectedVersion) {
        "Az" {
            $modulePath = Join-Path $profilePath "AzModules\Az"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "Az.psd1"
        }
        "AzureRM" {
            $modulePath = Join-Path $profilePath "AzureRMModules\AzureRM"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "AzureRM.psd1"
        }
        Default { }
    }
    Write-Host "Import Module from $modulePath"
    Import-Module $modulePath -Global
}
function Show-Tooltip {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$body, 
        [int]$timeout = 1, 
        [string]$tilte = "notify", 
        [ValidateSet("Error", "Info", "None", "Warning")]$toolTipIcon = "Info"
    )
    process {
        [Void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $powerShellExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($powerShellExe)
        $notifyIcon.Icon = $icon
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip($timeout, $tilte, $body, $toolTipIcon)        
    }
}

function Start-Periodic-Notify {
    param(
        [int]$timespan = 60,
        [string]$message = "time notify",
        [int]$notifyTimes = 0,
        [bool]$notify = $true
    )
    process {
        $notifyCount = 0
        $startDate = Get-Date
        $notifyDate = $startDate.AddSeconds(0)        
        while ($true) {
            $spendTime = $($notifyDate - $startDate).ToString()
            Write-Host "$message ($notifyCount): $spendTime "
            if ($notify) {
                Write-Output "$message ($notifyCount): $spendTime " | Show-Tooltip
            }
            $notifyCount ++
            $notifyDate = $notifyDate.AddSeconds($timespan)
            if ($notifyTimes -ne 0 -and ($notifyCount -ge $notifyTimes)) {
                break;
            }
            Start-Sleep $($notifyDate - $(Get-Date)).TotalSeconds
        }
    }
}

function Set-MyVirtualVmSize {
    param(
        [ValidateSet(
            "Standard_DS1_v2", 
            "Standard_DS2_v2"
        )]$size = "Standard_DS1_v2",
        [ValidateSet(
            "Standard_LRS",
            "StandardSSD_LRS", 
            "Premium_LRS"
        )]$storageType = 'Standard_LRS',
        [string]$rgName = $env:defaultResourceGroup
    )
    process {
        # if (-not $(Get-Module Az.Accounts)) {
        #     Write-Error "Az Module Not Found. Please Install Az Module 'Install-Module -Name Az'"
        #     return
        # }

        Get-Command Connect-AzAccountAsMyServicePrincipal -ea SilentlyContinue | Out-Null
        if ($? -eq $true) {
            Connect-AzAccountAsMyServicePrincipal
        }
        else {
            Connect-AzAccount
        }

        if (-not $rgName) {
            $rgName = Read-Host "Please type resource group name"
        }
        $vms = Get-AzVM -resourceGroupName $rgName

        # Stop and deallocate the VM before changing the size
        $vms | Stop-AzVM -Force

        # Change the VM size to a size that supports Premium storage
        # Skip this step if converting storage from Premium to Standard
        foreach ($vm in $vms) {
            $vm.HardwareProfile.VmSize = $size
            Update-AzVM -VM $vm -ResourceGroupName $rgName
        }

        # Get all disks in the resource group of the VM
        $vmDisks = Get-AzDisk -ResourceGroupName $rgName 

        # For disks that belong to the selected VM, convert to Premium storage
        foreach ($disk in $vmDisks) {
            if ($($vms | ForEach-Object { $_.Id } ) -contains $disk.ManagedBy) {
                $diskUpdateConfig = New-AzDiskUpdateConfig -AccountType $storageType
                Update-AzDisk -DiskUpdate $diskUpdateConfig -ResourceGroupName $rgName `
                    -DiskName $disk.Name
            }
        }
    }
}

function Start-MyVirtualMachines {
    param (
        [string]$resourceGroup = $env:defaultResourceGroup,
        [switch]$asJob
    )
    process {
        $startTime = Get-Date
        Get-Command Connect-AzAccountAsMyServicePrincipal -ea SilentlyContinue | Out-Null
        try {
            if ($? -eq $true) {
                Connect-AzAccountAsMyServicePrincipal
            }
            else {
                Connect-AzAccount
            }
        }
        catch {
            $_
            return;
        }
        if (-not $(Get-AzResourceGroup -Name $resourceGroup)) {
            Write-Host "Resource group not found."
            return
        }
        $VMhasLaunched = Get-AzVM -ResourceGroupName $resourceGroup | % { Start-AzVM -Id $_.Id  -AsJob }
        if (-not $asJob) {
            $VMhasLaunched | Wait-Job
            $totalTime = $($(Get-Date) - $startTime).ToString()
            Write-Host "Virtual Machine has been launched in $totalTime" | Show-Tooltip
            Write-Host "Virtual Machine has been launched in $totalTime"     
        }
        else {
            Register-ObjectEvent $VMhasLaunched -EventName "StateChanged" -SourceIdentifier JobStateChanged -Action {
                $totalTime = $($(Get-Date) - $startTime).ToString()
                Write-Host "Virtual Machine has been launched in $totalTime" | Show-Tooltip
                Write-Host "Virtual Machine has been launched in $totalTime"
                $global:sender1 = $sender
                $global:event1 = $Event
                $global:subscriber = $EventSubscriber
                $global:source = $SourceEventArgs
                $global:SourceArgs1 = $SourceArgs
                Unregister-Event -SourceIdentifier JobStateChanged         
            }
        }
    }
}

function Remove-EventViewerAllLogs {
    param (
        [switch]$confirm = $true
    )
    process {
        if ($confirm) {
            $result = Read-Host 'Delete All Saved Logs on EventViewr (y/n)';
            if ($result -ne 'y') {
                Write-Host 'abort!' -ForegroundColor Red
                return;
            }
        }
        Start-Process powershell.exe -ArgumentList '-Command "Remove-Item -Recurse -Force ""C:\ProgramData\Microsoft\Event Viewer\ExternalLogs\*\"""' -Verb runas -WindowStyle Hidden
    }
}

Export-ModuleMember -Function *
