#
# by kentork
# see https://gist.github.com/bf783d2a5378f32dbacb40d8897e7942.git
#
function setenv($key, $value, $target) {
    if (! $target) {
      $target = "User"
    }
    if (($target -eq "Process") -Or ($target -eq "User") -Or ($target -eq "Machine")) {
      $now = [environment]::getEnvironmentVariable($key, $target)
      if ($now) {
        $tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
        $result = $host.ui.PromptForChoice("", "Already Exists. Overwrite ?", @(
          New-Object $tChoiceDescription ("&Yes")
          New-Object $tChoiceDescription ("&No")
        ), 1)
        switch ($result) {
          0 {break}
          1 {
            Write-Host "`r`nAborted." -ForegroundColor DarkRed
            return
          }
        }
      }
      [environment]::setEnvironmentVariable($key, $value, $target)
      [environment]::setEnvironmentVariable($key, $value, "Process")
    } else {
      Write-Host "Failure ! - Invalid Target" -ForegroundColor DarkYellow
    }
  }
  function setpath($value, $target) {
    if (! $target) {
      $target = "User"
    }
    if (($target -eq "Process") -Or ($target -eq "User") -Or ($target -eq "Machine")) {
      $item = Convert-Path $value
  
      $path = [environment]::getEnvironmentVariable("PATH", $target)
      $list = $path -split ";"
  
      if (! $list.Contains($item)) {
        $_path = $path + ";" + $item + ";"
        $newpath = $_path -replace ";;", ";"
        [environment]::setEnvironmentVariable("PATH", $newpath, $target)
  
        $_path = [environment]::getEnvironmentVariable("PATH", "Process") + ";" + $item + ";"
        $newpath = $_path -replace ";;", ";"
        [environment]::setEnvironmentVariable("PATH", $newpath, "Process")
      } else {
        Write-Host "Already Exists." -ForegroundColor DarkYellow
      }
    } else {
      Write-Host "Failure ! - Invalid Target" -ForegroundColor DarkRed
    }
  }

  Export-ModuleMember -Function *
