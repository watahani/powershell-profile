function Get-HashFromString {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String,
        [ValidateSet(
            "SHA1",
            "SHA256",
            "SHA384",
            "SHA512",
            "MD5"
        )]$Algorithm = "SHA256"
    )
    process {
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($string)
        $writer.Flush()
        $stringAsStream.Position = 0
        $hash = Get-FileHash -InputStream $stringAsStream | Select-Object Hash
        return $hash.Hash
    }
}

function Convert-HexToByteArray {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$hex
    )
    process {
        $hex = $hex.Trim()
        $splitStrings = @(":", " ")
        foreach ($s in $splitStrings) {
            $hex = $hex.replace($s,"")
        }
        if ($hex.Length % 2 -ne 0){
            throw "HEX string lenght should be even"
        }

        $Bytes = [byte[]]::new($hex.Length / 2)
        
        For($i=0; $i -lt $hex.Length; $i+=2){
            $Bytes[$i/2] = [convert]::ToByte($hex.Substring($i, 2), 16)
        }
        return $Bytes
    }
}

Export-ModuleMember -Function *
