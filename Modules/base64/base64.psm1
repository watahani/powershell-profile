
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

Export-ModuleMember -Function *