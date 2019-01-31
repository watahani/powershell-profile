# by kentork 
# https://gist.github.com/kentork/3d4be89cdd501d815e8ab03268bbb41c
# article - https://qiita.com/kikuchi_kentaro/items/f500f261d1292ebe2941

function gh {
    Param(
      [ValidateSet("show","open","clone","find","grep","get","rm","cd","pushd","dir","edit","pwd","list","ls","register","create")][Parameter(Mandatory=$false)][string]$subcommand,
      [Parameter(Mandatory=$false)][switch]$g,   # globally (public)
      [Parameter(Mandatory=$false)][switch]$e,   # edit
      [Parameter(Mandatory=$false)][switch]$d,   # directory
      [Parameter(Mandatory=$false)][switch]$r,   # remote
      [Parameter(Mandatory=$false)][switch]$p,   # purge
      [Parameter(Mandatory=$false)][string]$arg1
    )
  
    switch ($subcommand) {
      "register" { gh-register $arg1 }
      "create" { gh-create }
      "clone" { gh-clone $arg1 }
      "get" { gh-clone $arg1 }
      "show" { gh-show $arg1 $g }
      "open" { gh-show $arg1 $true }
      "rm" { gh-rm $arg1 $r $p }
      "list" { gh-list $arg1 }
      "ls" { gh-list $arg1 }
      "cd" { gh-cd $arg1 }
      "pushd" { gh-pushd $arg1 }
      "pwd" { gh-pwd $arg1 }
      "dir" { gh-dir $arg1 }
      "edit" { gh-edit $arg1 }
      "find" { gh-find $arg1 $e $d }
      "grep" { gh-grep $arg1 $e $d }
      "-h" { gh-help }
      default { gh-help }
    }
  }
  
  $IDE = "code {0}"
  $EDITOR = "micro {1} {0}"
  # $EDITOR = "subl -n -w {0}"
  
  function gh-help {
    Write-Host "
  usage: gh <subcommand> [option]
    register [<account>]     - register account to gh
  
    create                   - create new Github repo
  
    clone(get) [<repo>]      - search a repo incrementally (or specified <repo>) and clone it
  
    show .                   - show the Github page of the current directory repo
    show [<repo>]            - select from local repos incrementally (or specified <repo>) and show its Github page
    show -g                  - search in global Github and select incrementally, and show its Github page
    open                     - alias to 'show -g'
  
    rm [-r] [-p] .           - remove the current directory repo
                               '-r' can make deleting with remote repo (require the token has 'delete repo' scope)
                               '-p' is purge mode, it deletes completely (if non, the deleted directory moves to trash)
    rm [-r] [-p] [<repo>]    - select from local repos incrementally (or specified <repo>) and remove it
  
    list(ls) [<query>]       - list local repos (with query string)
  
    cd    [<repo>]           - select from local repos incrementally (or specified <repo>) and move to there
    pushd [<repo>]           - select from local repos incrementally (or specified <repo>) and move to there with saving previous path to stack
                               if you will undo moving, enter 'popd'
    pwd   [<repo>]           - select from local repos incrementally (or specified <repo>) and output path and copy to clipboard
    dir   [<repo>]           - select from local repos incrementally (or specified <repo>) and launch explorer
    edit  [<repo>]           - select from local repos incrementally (or specified <repo>) and launch editor
  
    find . [-e][-d]          - find a file incrementally in the current directory repo
                               '-e' you can open it with an editor
                               '-d' you can open it with an explorer
    find   [-e][-d] [<repo>] - select from local repos incrementally (or specified <repo>) and find a file incrementally in it
  
    grep . [-e][-d]          - grep contents incrementally in the current directory repo
                               '-e' you can open it with an editor
                               '-d' you can open it with an explorer
    grep   [-e][-d] [<repo>] - select from local repos incrementally (or specified <repo>) and grep contents incrementally in it
    "
  }
  
  function gh-register($account) {
    if (! $account) {
      $account = Read-Host("Enter your account")
      if (! $account) {Write-Abort "`r`nAborted."; return}
    }
  
    $config = Load-Config
    if ($config -ne $null -and $config.accounts.ContainsKey($account)) {
      $ok = Confirm-No "'$account' is already Exists. Overwrite ?"
      if (! $ok) {Write-Abort "`r`nAborted."; return}
    }
  
    $token = Read-HostSecure "Enter your token"
  
    $progressPreference = 'silentlyContinue'
    $header = @{Authorization = "token $token"}
    try { $user_resp = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $header }
    catch { Write-Abort "Can not access to github api 'user' !`r`nAborted."; return }
    try { $email_resp = Invoke-RestMethod -Uri "https://api.github.com/user/public_emails" -Headers $header }
    catch { Write-Abort "Can not access to github api 'user/public_emails' !`r`nAborted."; return }
  
    $config.accounts[$account] = @{user=$user_resp.login; token=$token; email=$email_resp.email }
    $config | ConvertTo-Json | Out-File "~/.ghconfig"
  
    Write-Success "`r`nRegisterd !`r`n"
    [ordered]@{ account=$account; user=$user_resp.login; token=(Output-MaskedString $token); email=$email_resp.email }
  }
  function gh-create {
    $config = Load-Config
    if ($config -ne $null -and $config.accounts.get_Count() -gt 0) {
      $user = $config.accounts.Keys | fzf --select-1 --header="Select a user or organization"
      if ($user) { $account = $config.accounts[$user] }
      else { Write-Abort "`r`nAborted."; return }
    } else { Write-Warn "No registered accounts`r`n`r`nYou can register via 'gh register' command`r`n`r`n"; Write-Abort "Aborted."; return }
  
    $repository = Read-Host("Enter the repository name [ github.com/$user/<REPOSITORY> ]")
    if (! $repository) { Write-Warn "Can not create repository with empty name`r`n`r`n"; Write-Abort "Aborted."; return }
    if (Exists-LocalRepository -Project "$user/$repository") { Write-Warn "Prject is already exists on local`r`n`r`n"; Write-Abort "Aborted."; return }
    if (Exists-RemoteRepository -Project "$user/$repository") { Write-Warn "Prject is already exists on Github`r`n`r`n"; Write-Abort "Aborted."; return }
  
    $description = Read-Host("Enter the repository description")
    $public = Confirm-Yes "Is Public ?"
    Write-Host "`r`n"
  
    $continue = Confirm-Yes "Create 'https://github.com/$user/$repository' repository. Is it OK ?"
    if (! $continue){ Write-Abort "`r`nAborted."; return }
  
    $folder = New-Item "$(ghq root)\github.com\$user\$repository" -ItemType Directory
  
    Push-Location $folder
      $Env:GITHUB_TOKEN = $account.token
  
        git init | out-null
        git config --local user.name $account.user
        git config --local user.email $account.email
  
        $remote_url = "https://$($account.user):$($account.token)@github.com/$user/$repository"
        git remote add origin $remote_url
  
        $pub_opt = if(! $public){"-p "}
        $desc_opt = if($description){'-d "'+$description+'" '}
        $command = "hub create $pub_opt $desc_opt $user/$repository"
        Invoke-Expression $command | out-null
  
      Remove-Item Env:GITHUB_TOKEN
  
      Write-Success "`r`Create empty repository !`r`n"
      $init = Confirm-Yes "Initialize ?"
      if($init) {
        $licenses = license --list | ? {$_ -ne ""} | ? {$_ -notmatch "^Ava.*$" } | % {$_.trim()}
        $licenses = @($licenses | ? {$_ -match "^mit.*$" }) + ($licenses | ? {$_ -notmatch "^mit.*$" })
        $license = $licenses | fzf --header="Select license" | % {($_ -Split " ")[0]}
        if($license) {
          license -o LICENSE.txt -n $user $license
        }
        $ignores = gibo --list | ? {$_ -ne ""} | ? {$_ -notmatch "^=.*$" }
        $ignores = @("") + (gibo --list | ? {$_ -ne ""} | ? {$_ -notmatch "^=.*$" })
        $ignore = $ignores | fzf -m --header="Select ignore setting ( multiple choice )"
        if($ignore) {
          Save-UTF8 -Contents (gibo $ignore) -Path .gitignore
        }
        Save-UTF8 -Contents $(Generate-Readme -Repo $repository -Desc $description -License $license -User $user) -Path README.md
        $command = $EDITOR -f "README.md", ""
        Invoke-Expression $command
  
        git add -A | out-null
        git commit -m "Initial Commit" 2>&1 | out-null
        git push origin master 2>&1 | out-null
      }
    Pop-Location
  
    Write-Success "`r`Complete !`r`n"
    hub browse "$user/$repository"
  }
  function gh-clone($project) {
    if (!$project) {
      $project = Search-RemoteRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
  
    Fetch-RemoteRepository -Project $project
  }
  function gh-show($project, $global) {
    if ($project -eq ".") {
      $project = Get-LocalRepositoryName
  
      if (!$project) { Write-Warn "Current directory is not a git repository`r`n"; Write-Abort "Aborted."; return}
    }
    if (!$project -and !$global) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if (!$project -and $global) {
      $project = Search-RemoteRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
  
    Open-RemoteRepository -Project $project
  }
  function gh-rm($project, $remote, $purge) {
    if ($project -eq ".") {
      $project = Get-LocalRepositoryName
  
      if (!$project) { Write-Warn "Current directory is not a git repository`r`n"; Write-Abort "Aborted."; return}
      cd (ghq root)
    }
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    if ($pwd -match ($project.replace('/', '\\')) ) { cd (ghq root) }
  
    $account = ($project -Split("/"))[0]
    if ($remote -and !(Registerd $account)) { Write-Warn "No registered accounts`r`nYou can't remove this remote repository`r`n`r`n"; Write-Abort "Aborted."; return }
  
  
    # delete local
    $deleted = Remove-LocalRepository -Project $project -Purge $purge
    if(!$deleted) { Write-Warn "You can't remove this local repository`r`n`r`n"; Write-Abort "`r`nAborted."; return }
  
    # delete remote
    if ($remote){
      $deleted = Remove-RemoteRepository -Project $project
      if(!$deleted) { Write-Warn "You can't remove this remote repository`r`n`r`n"; Write-Abort "`r`nAborted."; return }
    }
  }
  function gh-list($query) {
    if (!$query) {
      ghq list -p
    } else {
      ghq list -p $query
    }
  }
  function gh-cd($project) {
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    $path = "$(ghq root)/github.com/$project"
    cd $path
  }
  function gh-pushd($project) {
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    $path = "$(ghq root)/github.com/$project"
    pushd $path
  }
  function gh-pwd {
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    $path = Convert-Path "$(ghq root)/github.com/$project"
    $path
    Set-Clipboard -Value $path
  }
  function gh-dir($project) {
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    $path = "$(ghq root)/github.com/$project"
    ii $path
  }
  function gh-edit {
    if (!$project) {
      $project = Select-LocalRepository
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
    if ($project -and !(Exists-LocalRepository -Project $project)) {
      Write-Warn "'$project' does not exists in local`r`n"; Write-Abort "Aborted."; return
    }
  
    $path = "$(ghq root)/github.com/$project"
    $command = $IDE -f $path
    Invoke-Expression $command
  }
  function gh-find($project, $edit, $dir) {
    if ($project -eq ".") {
      $project = Get-LocalRepositoryName
  
      if (!$project) { Write-Warn "Current directory is not a git repository`r`n"; Write-Abort "Aborted."; return}
    }
    if ($project -and !(Test-Path "$(ghq root)/github.com/$project")) {
      Write-Warn "$(ghq root)/github.com/$project does not exists`r`n"; Write-Abort "Aborted."; return
    }
    if ($project) {
      $project = "github.com/$project"
    }
    if (!$project) {
      $project = Select-LocalRepositoryAndAccount
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
  
    $target = Join-Path (ghq root) $project
    Push-Location $target
    $path = cmd /c rg --files . | fzf --header=" in $($target.Replace("\", "/"))" --preview 'chroma --style=vim {}' --color light
    # $path = rg --files . | fzf --header=" in $($target.Replace("\", "/"))" --preview 'file --mime-encoding {} | grep -v "binary" && chroma --style=vim {}' --color light
    Pop-Location
  
    if ($path) {
      $path = Join-Path $target $path
  
      if($edit) { Invoke-Expression ($EDITOR -f $path, "") }
      elseif($dir) { ii (Split-Path $path -Parent) }
      else { $path }
    } else { Write-Abort "`r`nAborted." }
  }
  function gh-grep($project, $edit, $dir) {
    if ($project -eq ".") {
      $project = Get-LocalRepositoryName
  
      if (!$project) { Write-Warn "Current directory is not a git repository`r`n"; Write-Abort "Aborted."; return}
    }
    if ($project -and !(Test-Path "$(ghq root)/github.com/$project")) {
      Write-Warn "$(ghq root)/github.com/$project does not exists`r`n"; Write-Abort "Aborted."; return
    }
    if ($project) {
      $project = "github.com/$project"
    }
    if (!$project) {
      $project = Select-LocalRepositoryAndAccount
  
      if (!$project) { Write-Abort "Aborted."; return}
    }
  
    $target = Join-Path (ghq root) $project
    $query=Read-Host("Searching - enter the query string")
    $string = cmd /c rg $query $target | fzf --preview 'echo {}' --color light
  
    if ($string) {
      $info = Resolve-GrepString -String $string
  
      if($edit) { Invoke-Expression ($EDITOR -f $info.file, "-startpos '$($info.line),0'") }
      elseif($dir) { ii ($info.file) }
      else { Convert-Path (Split-Path ($info.file) -Parent) }
    } else { Write-Abort "`r`nAborted." }
  }
  
  
  # Confirm Yes or No
  $HostChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
  function Confirm-Yes {
    Param(
      [string] $Message
    )
  
    $result = $host.ui.PromptForChoice("", $Message, @(
      New-Object $HostChoiceDescription ("&Yes")
      New-Object $HostChoiceDescription ("&No")
    ), 0)
    switch ($result) {
      0 {return $true}
      1 {return $false}
    }
  }
  function Confirm-No {
    Param(
      [string] $Message
    )
  
    $result = $host.ui.PromptForChoice("", $Message, @(
      New-Object $HostChoiceDescription ("&Yes")
      New-Object $HostChoiceDescription ("&No")
    ), 1)
    switch ($result) {
      0 {return $true}
      1 {return $false}
    }
  }
  
  
  # Console Message
  function Write-Abort {
    Param(
      [string] $Message
    )
  
    Write-Host $Message -ForegroundColor DarkRed
  }
  function Write-Warn {
    Param(
      [string] $Message
    )
  
    Write-Host $Message -ForegroundColor DarkYellow
  }
  function Write-Success {
    Param(
      [string] $Message
    )
  
    Write-Host $Message -ForegroundColor DarkCyan
  }
  
  
  # Local Repository
  function Is-GitRepository {
    git rev-parse 2>&1 | out-null
    if($lastexitcode -eq 0) {
      $true
    } else {
      $false
    }
  }
  function Get-LocalRepositoryName {
    if (Is-GitRepository) {
      return ((git config remote.origin.url) -Split "github.com/")[1]
    } else {
      return ""
    }
  }
  function Exists-LocalRepository {
    Param(
      [string] $Project
    )
  
    if (Test-Path "$(ghq root)/github.com/$Project") {
      return $true
    } else {
      return $false
    }
  }
  function Select-LocalRepository {
    $project = (ghq list | fzf --header="Select a project")
  
    if ($project) {
      $splitted = $project -Split "/"
      return "$($splitted[1])/$($splitted[2])"
    } else {
      return ""
    }
  }
  function Select-LocalRepositoryAndAccount {
    $all = @("github.com/")
    $repos = ghq list
    $accounts = $repos | %{ ($_.split('/'))[1] } | Get-Unique | %{ "github.com/$_/"}
    $list = $all + $accounts + $repos
  
    $project = $list | fzf --header="Select root folder"
  
    if ($project) {
      return $project
    } else {
      return ""
    }
  }
  function Remove-LocalRepository {
    Param(
      [string] $Project,
      [switch] $Purge
    )
  
    $root = ghq root
    $path = "$(ghq root)/github.com/$Project"
  
    while($true) {
      try {
        if($Purge) {
          Remove-Item -path $path -recurse -force -ErrorAction:Stop
        } else {
          Add-Type -AssemblyName Microsoft.VisualBasic
          [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($path,'OnlyErrorDialogs','SendToRecycleBin')
        }
        return $true
      } catch {
        $result = $host.ui.PromptForChoice("", "Can't remove this repository. You will retry after close all applications using files under this project.", @(
          New-Object $HostChoiceDescription ("&Retry")
          New-Object $HostChoiceDescription ("&Abort")
        ), 0)
        switch ($result) {
          0 {continue}
          1 {return $false}
        }
      }
    }
  }
  
  
  # Remote repository
  function Exists-RemoteRepository {
    Param(
      [string] $Project
    )
  
    try {
      $progressPreference = 'silentlyContinue'
      $response = Invoke-WebRequest -Uri "https://api.github.com/repos/$Project"
      $response.StatusCode.Value__
      return $true
    } catch {
      if($_.Exception.Response.StatusCode.Value__ -eq 404) {
        return $false
      }
      Write-Warn "Prject is already exists on local`r`n`r`n"
      Write-Abort "Aborted."
      exit 1
    }
  }
  function Search-RemoteRepository {
    Param(
      [string] $Project
    )
  
    $query=Read-Host("Searching - enter the query string")
  
    $token = Select-Token
    $token_opt = if($token -ne ""){"-t $token"}
    $command = "ghs $token_opt `"$query`" | fzf --header=`"Select a project`""
    $result = Invoke-Expression $command
  
    if ($result) {
      return ($result -split " ")[0]
    } else {
      return ""
    }
  }
  function Fetch-RemoteRepository {
    Param(
      [string] $Project
    )
  
    $json = Load-Config
  
    $_projrct = $Project -split "/"
    $account = $_projrct[0]
  
    if ($json -ne $null -and $json.accounts.ContainsKey($account)) {
      $config = $json.accounts[$account]
      ghq get "https://$($config.user):$($config.token)@github.com/$Project"
  
      $path = Join-Path $(ghq root) "github.com" | Join-Path -ChildPath $Project
      Push-Location $path
      git config --local user.name $config.user
      git config --local user.email $config.email
      Pop-Location
    } else {
      ghq get $Project
    }
  }
  function Remove-RemoteRepository {
    Param(
      [string] $Project
    )
  
    $account = ($project -Split("/"))[0]
    $token = Select-Token $account
    $header = @{Authorization = "token $token"}
  
    try {
      Invoke-RestMethod -Uri "https://api.github.com/repos/$Project" -Method Delete -Headers $header
      return $true
    } catch {
      return $false
    }
  }
  function Open-RemoteRepository {
    Param(
      [string] $Project
    )
  
    hub browse $Project
  }
  
  
  # Config manipulation
  function Load-Config {
    if (Test-Path "~/.ghconfig") {
      $text = Get-Content "~/.ghconfig" | Out-String
      try {
        Add-Type -AssemblyName "System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -ErrorAction Stop
        $parser = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
        return $parser.Deserialize($text, 'Hashtable')
      } catch {
        return @{ "accounts" = @{} }
      } finally {
        $parser = $null
      }
    } else {
      @{ "accounts" = @{} }
    }
  }
  function Select-Token {
    Param(
      [string] $Account
    )
  
    $config = Load-Config
  
    if ($config -ne $null -and $config.accounts.get_Count() -gt 0) {
      if ($Account) {
        return $($config.accounts[$Account]).token
      } else {
        return $($config.accounts.Values.GetEnumerator() | select -first 1).token
      }
    } else {
      return ""
    }
  }
  function Registerd {
    Param(
      [string] $Account
    )
  
    $config = Load-Config
  
    if ($config -ne $null -and $config.accounts.get_Count() -gt 0) {
      return ! $($config.accounts[$Account] -eq $null)
    } else {
      return $false
    }
  }
  function Read-HostSecure {
    Param(
      [string] $Message
    )
  
    $string = Read-Host $Message -AsSecureString
    $string = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($string)
    $string = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($string)
    # $string = $string.Trim()
  
    return $string
  }
  function Output-MaskedString {
    Param(
      [string] $String
    )
  
    $first = $String[0]
    $second = $String[1]
    $third = $String[2]
    $other = -join ((0..($String.length - 3)) | % {"*"})
    return "$first$second$third$other"
  }
  
  
  # Split string to file and line number
  function Resolve-GrepString {
    Param(
      [string] $String
    )
  
    $splitted = $string -Split ":"
    $file = "$($splitted[0]):$($splitted[1])"
    $line = $splitted[2]
  
    return @{file = $file; line = $line}
  }
  
  # Save with utf-8 without BOM
  function Save-UTF8 {
    Param(
      [array] $Contents,
      [string] $Path
    )
  
    $Contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Encoding Byte -Path $Path
  }
  
  # Resolve path string
  function Resolve-Path2 {
    Param(
      [string] $Path
    )
  
    return [IO.Path]::Combine($pwd, $Path)
  }
  
  # Create Readme.md
  function Generate-Readme {
    Param(
      [string] $Repo,
      [string] $Desc,
      [string] $License,
      [string] $User
    )
  
    $readme = "# " + $Repo + "`n"
    if($Desc) {
      $readme += "`n"
      $readme += $Desc + "`n"
    }
    if($License) {
      license --list | ? {$_ -match $License } | % {$_ -match "\(.+\)"} | out-null
      $long_name = $Matches[0]
  
      $readme += "`n"
      $readme += "# License`n"
      $readme += "`n"
      $readme += "This project is licensed under the $($long_name.Trim('()')).`n`n"
      $readme += "Copyright (c) $((Get-Date).Year) $User.`n"
    }
  
    return $readme
  }

  Export-ModuleMember -Function *