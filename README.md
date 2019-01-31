# powershell profile

clone this repository to Powershell profile folder.
And update submodule.

```ps
PS> git clone https://github.com/watahani/powershell-profile $(Split-Path $profile)
PS> cd $(Split-Path $profile)
PS> git submodule update -i
```

or

```ps
PS> git clone -recursive https://github.com/watahani/powershell-profile $(Split-Path $profile)
```

## add modules

Make a new folder in [Modules](./Modules) and make psm1 file with the same name as folder.

```ps1
# DONT FORGET TO EXPORT MODULE FUNCTIONS
Export-ModuleMember -Function *
```
