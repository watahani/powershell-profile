# powershell profile

clone this repository to Powershell profile folder.
And update submodule.

```ps
PS> git clone xxxx $(Split-Path $profile)
PS> cd $(Split-Path $profile)
PS> git submodule update -i
```
