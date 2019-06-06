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
function Test-Command-Enable{
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]$base64Url
    )
    process {
        $missingCharacters = (4 - $base64Url.Length % 4) % 4
        if($missingCharacters -gt 0)
        {
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
    $profilePath = $(Split-Path $PROFILE)
    $azureADModule = Get-Module -Name AzureADPreview
    if(-not $azureADModule){
        $azureADModule = Get-Module -Name AzureAD
    }
    if($azureADModule){
        $version = $azureADModule.Name
        Remove-Module -Name $version
    }else{
        $version = "AzureADPreview"
    }


    switch ($version) {
        "AzureADPreview" {
            $modulePath = Join-Path $profilePath "AzureAD"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "AzureAD.psd1"
        }
        "AzureAD" {
            $modulePath = Join-Path $profilePath "AzureADPreview"
            $modulePath = Get-ChildItem $modulePath | Select-Object -First 1
            $modulePath = Join-Path $modulePath.FullName "AzureADPreview.psd1"
        }
        Default {}
    }
    Write-Host "Import Module from $modulePath"
    Import-Module $modulePath
}

Export-ModuleMember -Function *