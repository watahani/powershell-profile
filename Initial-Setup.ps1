

Install-PackageProvider -Name Nuget -Force
# https://github.com/PowerShell/SystemLocaleDsc
Install-Module SystemLocaleDsc -Force -SkipPublisherCheck

Save-Module -Name AzureAD -Path $(Split-Path $profile)
Save-Module -Name AzureADPreview -Path $(Split-Path $profile)


