# Windows で Linux 形式のパスを作る (docker run 時の -v オプションに渡すにはこの形式が必要)
function pwd_as_linux {
    "/$((pwd).Drive.Name.ToLowerInvariant())/$((pwd).Path.Replace('\', '/').Substring(3))"
}
# File-Hash を取得する
function Get-File-Sha1Hashes {
    $files = Get-ChildItem -Force
    foreach($file in $files){
        if($file.Extension -eq ".sha1"){
            continue
        }
        if(!$file.PSIsContainer){
        Get-FileHash $file -Algorithm SHA1 | Out-File -FilePath ($file.Name + ".sha1") -Encoding utf8
        }
    }
}
Import-Module 'C:\Users\HANIYAMA\Documents\WindowsPowerShell\posh-git\src\posh-git.psd1'
