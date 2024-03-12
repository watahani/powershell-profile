function Test-IsAdministrator {
    return ([Security.Principal.WindowsPrincipal]`
            [Security.Principal.WindowsIdentity]::GetCurrent()`
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Enable TLS 1.2
If (-Not (Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319'))
{
    New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'))
{
    New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'))
{
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'Enabled' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'DisabledByDefault' -Value '0' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'))
{
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'Enabled' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'DisabledByDefault' -Value '0' -PropertyType 'DWord' -Force | Out-Null

# install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

if(Test-IsAdministrator)
{
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
} else 
{
    iwr -useb get.scoop.sh | iex
}
scoop install git
scoop install 7zip python azure-cli curl jq -g
scoop bucket add extras
scoop install chromium firefox -g

Install-PackageProvider -Name Nuget -Force
# https://github.com/PowerShell/SystemLocaleDsc
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module SystemLocaleDsc -Force -SkipPublisherCheck
Install-Module PowerShellGet -AllowClobber -Force

Find-Module -Name AzureAD -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}
Find-Module -Name AzureADPreview -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}
Find-Module -Name AzureRM -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}
Find-Module -Name Az -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}


$AzPath = Join-Path $(Split-Path $profile) "AzModules"
New-Item -ItemType Directory -Force $AzPath | Out-Null
Save-Module -Name Az -Path $AzPath

$AzureRMPath = Join-Path $(Split-Path $profile) "AzureRMModules"
New-Item -ItemType Directory -Force $AzureRMPath | Out-Null
Save-Module -Name AzureRM -Path $AzureRMPath
