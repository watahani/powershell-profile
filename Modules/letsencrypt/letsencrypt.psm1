
function Get-Certificate-WinACME {
    param(
        [Parameter(Mandatory = $false)]
        [string]$targetHost,

        [Parameter(Mandatory = $false)]
        [string]$tenantId,

        [Parameter(Mandatory = $false)]
        [string]$clientId,

        [Parameter(Mandatory = $false)]
        [string]$clientSecret,

        [Parameter(Mandatory = $false)]
        [string]$subscriptionId,

        [Parameter(Mandatory = $false)]
        [string]$resourceGroupName
    )
    process {
        Set-Location $env:USERPROFILE
        # see https://github.com/PKISharp/win-acme/wiki/Azure-DNS-validation

        # winacmeVersion
        $winacmeVersion = "v2.0.7.315"

        if(-not (Test-Path ".\win-acme\wacs.exe")){
            # download win-acme
            Write-Host Download win-acme...
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            (New-Object System.Net.WebClient).DownloadFile("https://github.com/PKISharp/win-acme/releases/download/$winacmeVersion/win-acme.$winacmeVersion.zip" , ".\win-acme.zip" )
            (New-Object System.Net.WebClient).DownloadFile("https://github.com/PKISharp/win-acme/releases/download/$winacmeVersion/win-acme.azure.$winacmeVersion.zip" , ".\win-acme-azure.zip" )
            Write-Host Extract win-acme...
            Expand-Archive .\win-acme.zip
            Expand-Archive .\win-acme-azure.zip -DestinationPath .\win-acme
            (New-Object System.Net.WebClient).DownloadFile("https://gist.github.com/watahani/b22e4f2ce1f05eb972241adc593ab56c/raw/a1af3e69bd1476b276578834fd31c114ed88e472/copy-pfxfile.ps1" , ".\win-acme\copy-pfxfile.ps1" )
            mkdir "win-acme\certificates"
        }

        $settingxml = [xml](Get-Content .\win-acme\wacs.exe.config)

        if(-not $settingxml.configuration.runtime.loadFromRemoteSources){
            Write-Host add loadFromRemoteSources option to setting xml...
            # <loadFromRemoteSources enabled="true"/>
            $loadFromRemoteSources = $settingxml.CreateElement("loadFromRemoteSources")
            $loadFromRemoteSources.SetAttribute("enabled", "true")
            $settingxml.configuration.runtime.AppendChild($loadFromRemoteSources)
            $settingxml.Save(".\win-acme\wacs.exe.config")
        }

        if (-not $targetHost) {
            $targetHost = Read-Host "enter target hostname"
        }
                
        if (-not $resourceGroupName) {
            $resourceGroupName = Read-Host "enter resource group name"
        }
        
        if (-not $clientId) {
            $clientId = Read-Host "enter client id which have permission to edit dns zone"
        }
        
        if(-not $clientSecret) {
            $clientSecret = Read-Host "enter client secret"
        }
        
        if(-not $tenantId) {
            $tenantId = Read-Host "enter tenant id"
        }
        
        if(-not $subscriptionId) {
            $subscriptionId = Read-Host "enter subscription id"
        }
        
        

        $confirmed = Read-Host "Create Certificate for $targetHost ? [y/n]"
        if($confirmed -ne "y") {
            Write-Host "abort" -ForegroundColor Red
            return;
        }
        Set-Location $(Join-Path $env:USERPROFILE "win-acme")
        .\wacs.exe  --validationmode dns-01 --validation azure `
                    --azuretenantid $tenantId --azureclientid $clientId --azuresecret $clientSecret --azuresubscriptionid $subscriptionId --azureresourcegroupname $resourceGroupName `
                    --target manual --host $targetHost --store pemfiles --pemfilespath $(pwd) --installation script --script ".\copy-pfxfile.ps1" --scriptparameters "'{CertThumbprint}' '{CertFriendlyName}' '{CacheFile}' '{CachePassword}'"
        }
}

Export-ModuleMember -Function *
