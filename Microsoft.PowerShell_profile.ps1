# Windows Path to Linux
function pwd_as_linux {
    "/$((pwd).Drive.Name.ToLowerInvariant())/$((pwd).Path.Replace('\', '/').Substring(3))"
}
# Calculate File-Hashes
function Get-File-Sha1Hashes {
    $files = Get-ChildItem -Force
    foreach ($file in $files) {
        if ($file.Extension -eq ".sha1") {
            continue
        }
        if (!$file.PSIsContainer) {
            $(Get-FileHash $file -Algorithm SHA1).Hash | Out-File -FilePath ($file.Name + ".sha1") -Encoding utf8
        }
    }
}

# Check Command Enable
function Command-Enable ($command) {
    Get-Command $command -ea SilentlyContinue | Out-Null
        if ($? -eq $true) { 
            return $true
        }
        return $false
}

# String To Base64
function Encode-Base64($planeText){
    $byte = ([System.Text.Encoding]::Default).GetBytes($planeText)
    $b64enc = [Convert]::ToBase64String($byte)
    return $b64enc
}

# Base64 To Plane Text 
function Decode-Base64($base64){
    $byte = [System.Convert]::FromBase64String($base64)
    $txt = [System.Text.Encoding]::Default.GetString($byte)
    return $txt
}


$ProfileFolder = Split-Path $profile
Import-Module $ProfileFolder\bf783d2a5378f32dbacb40d8897e7942\profile.ps1
Import-Module $ProfileFolder\3d4be89cdd501d815e8ab03268bbb41c\profile.ps1
Import-Module $ProfileFolder\posh-git\src\posh-git.psd1
try { $null = gcm pshazz -ea stop; pshazz init } catch { }
