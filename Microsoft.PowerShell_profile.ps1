# Windows で Linux 形式のパスを作る (docker run 時の -v オプションに渡すにはこの形式が必要)
function pwd_as_linux {
    "/$((pwd).Drive.Name.ToLowerInvariant())/$((pwd).Path.Replace('\', '/').Substring(3))"
}
# File-Hash を取得する
function Get-File-Sha1Hashes {
    $files = Get-ChildItem -Force
    foreach ($file in $files) {
        if ($file.Extension -eq ".sha1") {
            continue
        }
        if (!$file.PSIsContainer) {
            Get-FileHash $file -Algorithm SHA1 | Out-File -FilePath ($file.Name + ".sha1") -Encoding utf8
        }
    }
}
$ProfileFolder = Split-Path $profile
Import-Module $ProfileFolder\bf783d2a5378f32dbacb40d8897e7942\profile.ps1
Import-Module $ProfileFolder\3d4be89cdd501d815e8ab03268bbb41c\profile.ps1
Import-Module $ProfileFolder\posh-git\src\posh-git.psd1
