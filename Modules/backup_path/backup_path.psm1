function Backup-Path {
    Get-Date | Add-Content ~/.path -Encoding utf8
    [environment]::getEnvironmentVariable("PATH", "User") | Add-Content ~/.path -Encoding utf8
    [environment]::getEnvironmentVariable("PATH", "Machine") | Add-Content ~/.path -Encoding utf8
    "`r`n" | Add-Content ~/.path -Encoding utf8

    $saving = 20
    $maxline = 5 * $saving
    $contents = Get-Content ~/.path
    if ($contents.length -gt $maxline) {
        $contents | Select-Object -Skip ($contents.length - $maxline) | Set-Content -Encoding utf8 ~/.path
    }
}

Export-ModuleMember -Function *
