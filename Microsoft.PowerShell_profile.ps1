# 自動ログ取得開始
$LogFolder   = 'C:\_work\_Logs'
$TimeStamp   = (Get-Date -Format 'yyyyMMdd-HHmmss')
$UserInfo    = $Env:COMPUTERNAME + '-' + $Env:USERNAME
$LogFilePath = $LogFolder + '\PS_' + $TimeStamp + '_' + $UserInfo + '.log'

Start-Transcript -Path $LogFilePath -Append
Switch-AzureADModule

try { $null = gcm pshazz -ea stop; pshazz init } catch { }
