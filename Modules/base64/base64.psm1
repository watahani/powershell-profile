
# String To Base64
function Convert-PlainTextToBase64 {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$plainText
    )
    process {
        $bytes = ([System.Text.Encoding]::Default).GetBytes($plainText)
        $b64enc = Convert-BytesToBase64 $bytes
        return $b64enc
    }
}

# Convert bytes to base64 string
function Convert-BytesToBase64 {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [byte[]]$bytes
    )
    process {
        $b64enc = [Convert]::ToBase64String($bytes)
        return $b64enc
    }
}

function Convert-Base64ToBytes {
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$str
    )
    process {
        return [System.Convert]::FromBase64String($str)
    }
}

# Bytes To Base64Url
function Convert-BytesToBase64Url {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [byte[]]$bytes
    )
    process {
        $base64string = Convert-BytesToBase64 $bytes
        $base64Url = $base64String.TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $base64Url
    }
}

# Base64 To Plane Text 
function Convert-Base64ToPlainText {
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
function Convert-PlainTextToBase64Url {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$plainText
    )
    process {
        $base64string = Convert-PlainTextToBase64 $plainText
        return Convert-Base64ToBase64URL $base64string
    }
}

function Convert-Base64ToBase64URL {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$base64String
    )
    process {
        $base64Url = $base64String.TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $base64Url
    } 
}

function Convert-Base64URLToBase64 {
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
        return $base64String
    }
}

# Base64URL To Plane Text 
function Convert-Base64UrlToPlainText {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$base64Url
    )
    process {
        $base64String = Convert-Base64URLToBase64 $base64Url
        $plainText = Convert-Base64ToPlainText $base64String
        return $plainText
    }
}

# Base64URL To Bytes 
function Convert-Base64UrlToByte {
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$base64Url
    )
    process {
        $base64String = Convert-Base64URLToBase64 $base64Url
        return Convert-Base64ToBytes $base64String
    }
}

Export-ModuleMember -Function *