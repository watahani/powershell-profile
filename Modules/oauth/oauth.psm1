function ConvertFrom-CodeVerifier {
    <#
        .SYNOPSIS
            Generate Code Challenge from Code Verifier String

        .EXAMPLE
            ConvertFrom-CodeVerifier 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk' -Method s256
    #>
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$codeVerifier,
        [ValidateSet(
            "plain",
            "s256"
        )]$Method = "s256"
    )
    process {
        switch($Method){
            "plain" {
                return $codeVerifier
            }
            "s256" {
                # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7
                $stringAsStream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stringAsStream)
                $writer.write($codeVerifier)
                $writer.Flush()
                $stringAsStream.Position = 0
                $hash = Get-FileHash -InputStream $stringAsStream | Select-Object Hash
                $hex = $hash.Hash
        
                $bytes = [byte[]]::new($hex.Length / 2)
                    
                For($i=0; $i -lt $hex.Length; $i+=2){
                    $bytes[$i/2] = [convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $b64enc = [Convert]::ToBase64String($bytes)
                $b64url = $b64enc.TrimEnd('=').Replace('+', '-').Replace('/', '_')
                return $b64url     
            }
            default {
                throw "not supported method: $Method"
            }
        }
    }
}

function New-Randombytes {
    <#
    .SYNOPSIS
        Generate Random byte using System.Random
    #>
    [OutputType([byte[]])]
    param(
        [int]$length = 64
    )
    process {
        $bytes = [System.Byte[]]::new($length);
        [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($bytes);
        return $bytes
    }
}

function Convert-HashObjectToQueryString {
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Hashtable]$params
    )
    process {
        $queries = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        foreach($key in $params.Keys){
            $queries[$key] = $params[$key]
        }
        return $queries.ToString()
    }
}

function ConvertFrom-JWT([string]$rawToken)
{
    $parts = $rawToken.Split('.');
    $headers = Convert-Base64UrlToPlainText $parts[0]
    $claims = Convert-Base64UrlToPlainText $parts[1]
    $signature = Convert-Base64UrlToByte $parts[2]

    $customObject = [PSCustomObject]@{
        headers = ($headers | ConvertFrom-Json)
        claims = ($claims | ConvertFrom-Json)
        signature = $signature
    }

    Write-Verbose -Message ("JWT`r`n.headers: {0}`r`n.claims: {1}`r`n.signature: {2}`r`n" -f $headers,$claims,[System.BitConverter]::ToString($signature))
    return $customObject
}

Export-ModuleMember -Function *
