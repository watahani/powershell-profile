

Install-PackageProvider -Name Nuget -Force
# https://github.com/PowerShell/SystemLocaleDsc
Install-Module SystemLocaleDsc -Force -SkipPublisherCheck

Find-Module -Name AzureAD -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}
Find-Module -Name AzureADPreview -AllVersions | %{ Save-Module -Name $_.Name -RequiredVersion $_.Version -Path $(Split-Path $profile)}

$AzPath = Join-Path $(Split-Path $profile) "AzModules"
New-Item -ItemType Directory -Force $AzPath | Out-Null
Save-Module -Name Az -Path $AzPath

$AzureRMPath = Join-Path $(Split-Path $profile) "AzureRMModules"
New-Item -ItemType Directory -Force $AzureRMPath | Out-Null
Save-Module -Name AzureRM -Path $AzureRMPath
