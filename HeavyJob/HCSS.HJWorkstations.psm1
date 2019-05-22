<#
.SYNOPSIS
Script for fast updating of HeavyJob workstations.

.DESCRIPTION
Script for fast updating of HeavyJob workstations.

This is NOT a comprehensive install and does not address HeavyJob.xmls

.PARAMETER sourceHost
This should be the probably be the file server hosting HeavyJob and it should have an installed workstation

.PARAMETER targetHost
This is the workstation you wish to flip to large installs

.PARAMETER desiredBinPath
This is where the bin folder will be sent to and the new shortcuts paths will be based off of

.EXAMPLE
Import-Module .\HCSS.HJWorkstations.psm1
Invoke-HJDeployment "TS01" "FS01" "C:\HeavyJobWS"

.NOTES
Assumptions:
    1. HeavyJob was already installed on that computer
    2. They already have desktop icons in the public desktop folder
    3. Dll's are already registered
    4. The computer executing this script has the needed mapped drive matching the sourceHost's %programdata%\HCSS\HeavyJob.xml's configuration
    5. No one is currently running HeavyJob on the target's computer
#>

function Invoke-HJDeployment {
    [CmdletBinding()]
        param(
            [Parameter(Position=0,mandatory=$true,HelpMessage="Please provide a hostname that of a computer that has a large install")]
            [string] $sourceHost,        
            [Parameter(Position=1,mandatory=$true,HelpMessage="Please an array of hosts to deploy to")]
            [string] $targetHost,
            [Parameter(Position=2,mandatory=$true,HelpMessage="Example C:\HeavyJobWS")]
            [string] $desiredBinPath)
    
        process{
            $ErrorActionPreference = "Stop"
            Test-Parameters $sourceHost $targetHost
    
            Copy-BinFolder $sourceHost $targetHost
            Update-DesktopIcons $targetHost $desiredBinPath
        }
    } 
    
    function Copy-BinFolder($sourceHost, $targetHost){
        $binFolder = Get-BinFolder $sourceHost
        
        Write-Host "Copying from $($binFolder)" -ForegroundColor Yellow
    
        ##Ensure the folder is there to recieve the copy
        $binDestination = "\\$($targetHost)\c$\HeavyJobWS\"
        
        New-BinFolder $binDestination
    
        Write-Host "Copying to $($binFolder)" -ForegroundColor Yellow
    
        ##Force to overwrite
        ##-Container to maintain folder tree structure
        Copy-Item  $binFolder -Destination $binDestination -Container -Recurse -Force
    
        Write-Host "Copying complete" -ForegroundColor Yellow
    }
    
    <# This only updates existing icons instead of creating new ones #>
    function Update-DesktopIcons($targetHost, $newPath){
    
        #Constructors
        $filter = "HeavyJob"
        $folderPath = Get-PublicDesktop $targetHost  
        $_shell = New-Object -ComObject WScript.Shell 
        $_links = Get-ChildItem $folderPath -Filter *.lnk | Where-Object Name -Match "$($filter)*"
    
        Write-Host "Found lnk files $($_links)" -ForegroundColor Yellow    
                   
        foreach ($_link in $_links) {            
                
            $shorcut = $_shell.CreateShortcut( $_link.FullName)   
        
            $shorcut.TargetPath = "$($newPath)\Bin\HeavyJob.exe"
            $shorcut.WorkingDirectory = "$($newPath)\Bin\"
            $shorcut.Save()           
    
            Write-Host "New shortcut settings for $($targetHost)" -ForegroundColor Yellow
    
            $shorcut 
        } 
     
        Write-Host "Updating shorcuts complete" -ForegroundColor Yellow
    
        [Runtime.InteropServices.Marshal]::ReleaseComObject($_shell) | Out-Null
        [System.GC]::Collect()   
    }
    
    
    <# Begin Supporting functions  #>
    function Get-HeavyJobXmlData ($hostname){
        $configFile = Get-ChildItem "\\$($hostname)\c$\programdata\HCSS\HeavyJob.xml"
        $XmlLoader=(New-Object System.Xml.XmlDocument)
        $XmlLoader.Load($configFile.FullName)
    
        return $XmlLoader
    }
    
    function Get-BinFolder($hostname){
        $config = Get-HeavyJobXmlData $hostname
    
        $dataDir = [System.IO.DirectoryInfo]::new($config.HCSS.HEAVYJOB.INSTANCES.INSTANCE[0].DATADIRECTORY)
    
        $binPath = [System.IO.DirectoryInfo]::new("$($dataDir.Parent.FullName)\Bin")
    
        # Ensure there won't be any issues finding needed resources
        Test-FolderPath $dataDir
        Test-FolderPath $binPath
    
        return $binPath.FullName
    }
    
    function Get-PublicDesktop($hostname){
    
        $publicDesktop = [System.IO.DirectoryInfo]::new("\\$($hostname)\c$\Users\Public\Desktop")
    
        return $publicDesktop.FullName
    }
    
    function New-BinFolder($folder){
    
        Write-Host "Cleaning workstation folder $($folder)" -ForegroundColor Yellow
        If(Test-path $folder) 
            {
                Write-Host "Old version found, attempting to delete" -ForegroundColor Red
    
                Remove-item $folder -Recurse
                New-item $folder -ItemType Directory
            } 
            Else 
            {
                New-item $folder -ItemType Directory
            }
    }
    
    function Test-Parameters($sourceHost, $targetHost){
    
        #Ensure access to both machines
        Test-FolderPath "\\$($sourceHost)\c$"
        Test-FolderPath "\\$($targetHost)\c$"
    }
    
    #This is to ensure the script exits if there was a typo
    function Test-FolderPath($path){
    
        if ((Test-Path $path) -eq $false) {
            throw [System.Exception] "Access denied or could not find host path $($path)"
        }
    }
    <# End Supporting functions  #>
