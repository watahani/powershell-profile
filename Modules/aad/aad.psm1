Function Get-AADAccessToken(){
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$clientId,
        [String]$clientSecret,
        [String]$tenantId,
        [String]$scope='https://graph.microsoft.com/.default'
    )
    process {
        $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

        $body = @{
            client_id=$clientId;
            client_secret=$clientSecret;
            grant_type='client_credentials';
            scope='https://graph.microsoft.com/.default';
        }
        $tokenResp = Invoke-WebRequest -Uri $tokenEndpoint -Method POST -ContentType 'application/x-www-form-urlencoded' -Body $body

        $accessToken = $($tokenResp.Content | ConvertFrom-Json).access_token

        return $accessToken
    }
}

Function Invoke-AADGetCredentialTypeAPI() {
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$UserName
    )
    process {
        $res = Invoke-WebRequest -Uri "https://login.microsoftonline.com/common/GetCredentialType?mkt=ja" `
        -Method "POST" `
        -Headers @{
        "Accept"="application/json"
        } `
        -ContentType "application/json; charset=UTF-8" `
        -Body "{`"username`":`"$UserName`"}"

        $result = ConvertFrom-Json $res.Content
        return $result
    }
}

Function Convert-TenantNameToGuid() {
    param(
        [Parameter(Mandatory= $True, ValueFromPipeline = $True)]
        [String]$TenantName
    )
    process {
        $res = Invoke-RestMethod -Method GET -Uri "https://login.microsoftonline.com/$TenantName/.well-known/openid-configuration" -UseBasicParsing
        $tenantId = $res.authorization_endpoint.Split('/')[3]
        return $tenantId
    }
}

Function Get-TenantInfoFromGuid() {
    param(
        [Parameter(Mandatory= $True, ValueFromPipeline = $True)]
        [String]$TenantId
    )
    process {
        # need API Permission: CrossTenantInformation.ReadBasic.All
        Connect-MgGraph -ClientId $env:TENANT_INFO_APPID -TenantId $env:TENANT_INFO_TENANT_ID -CertificateThumbprint $env:TENANT_INFO_CERT_THUMBPRINT -ContextScope Process | Out-Null
        $res = Invoke-GraphRequest -Method GET -Uri "/beta/tenantRelationships/findTenantInformationByTenantId(tenantId='$tenantId')"
        return $res;
    }
}