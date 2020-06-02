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

function Convert-HexToString {
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
        $hexList = New-Object System.Collections.ArrayList
        for($i = 0; $i -lt $hex.Length; $i=$i+2){
            $hexList.Add($hex.Substring($i, 2)) | Out-Null
        }
        $chars = $hexList | ForEach-Object {[char][byte]"0x$_"}
        return $chars -Join ""
    }
}

Export-ModuleMember -Function *
