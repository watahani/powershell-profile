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

# String To Base64
function Encode-Base64 {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$plainText
    )
    process {
        $byte = ([System.Text.Encoding]::Default).GetBytes($plainText)
        $b64enc = [Convert]::ToBase64String($byte)
        return $b64enc
    }
}

# Base64 To Plane Text 
function Decode-Base64 {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$base64String
    )
    process {
        $byte = [System.Convert]::FromBase64String($base64String)
        $plainText = [System.Text.Encoding]::Default.GetString($byte)
        return $plainText
    }
}

# String To Base64
function Encode-Base64Url {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$plainText
    )
    process {
        $base64string = Encode-Base64 $plainText
        $base64Url = $base64String.TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $base64Url
    }
}

# Base64 To Plane Text 
function Decode-Base64Url {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$base64Url
    )
    process {
        $missingCharacters = (4 - $base64Url.Length % 4) % 4
        if ($missingCharacters -gt 0) {
            $missingString = New-Object System.String -ArgumentList @( '=', $missingCharacters )
            $base64Url = $base64Url + $missingString       
        }
        $base64String = $base64Url.Replace('-', '+').Replace('_', '/')
        $byte = [System.Convert]::FromBase64String($base64String)
        $plainText = [System.Text.Encoding]::Default.GetString($byte)
        return $plainText
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
                Write-Host "$message ($notifyCount): $spendTime " | Show-Tooltip
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

Export-ModuleMember -Function *