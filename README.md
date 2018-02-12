# PowerShell
A collection of PowerShell scripts for use with HCSS products 

## Requirements
- These functions are only tested on the newest version of PowerShell
- You must have local administrator or WMI access to all accessed computers
- All scripts might need slight changes to match your environment

## How To
- Open PowerShell on the computer you plan to run these from
- Excute the below command

```PowerShell
notepad $profile
``` 

- Add the functions into this notpad file to make it load with your profile next time PowerShell is opened
- Save & close the notepad file
- Reopen PowerShell

## Example Use

```PowerShell
Find-HJLoggedIn FS01 
```
