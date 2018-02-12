function Invoke-HJLogout {
    [CmdletBinding()]
		Param(
			[Parameter(
				Mandatory=$True,
				HelpMessage="Please enter the partial Active Directory Username:",
                Position=1
            )][string]$User, 
            [Parameter(
				Mandatory=$True,
				HelpMessage="Please enter the file server's name that HeavyJob is hosted on:",
                Position=2
            )][string]$Server
        )

    $ErrorActionPreference = "SilentlyContinue"
    
    ##Try to close the executables
    $pc = Get-WmiObject win32_serverconnection -ComputerName $Server | Where-Object username -like $($User + "*")
    $proc = Get-WmiObject -Class win32_process -Filter "name = 'HeavyJob.exe'" -computername $pc.ComputerName | Where-Object {$_.GetOwner().User -Like $($User + "*")}
	$proc.Terminate()
	$proc = Get-WmiObject -Class win32_process -Filter "name = 'HeavyJob.exe'" -computername $pc.PSComputerName | Where-Object {$_.GetOwner().User -Like $($User + "*")}
	$proc.Terminate()
     
    ##Enumerate if any files were left open
    $FileList = Invoke-Expression "& C:\Windows\System32\openfiles.exe /query /s $($Server) /fo CSV" | 
        ConvertFrom-Csv | Select-Object "ID","Accessed By","Open File (Path\executable)"

    ##This closes ALL files open with HeavyJob in the folder path. Tweak this to match logic that fits your organization's folder path naming convention.    
    $FilteredList = ($FileList | Where-Object {($_."Open File (Path\executable)" -Like "*heavyjob*" -and $_."Accessed By" -Like $($User + "*"))} | Select-Object "ID")  
    
    ##Close open files on the file server
	$FilteredList | ForEach-Object {openfiles /disconnect /s $Server /id $($_."ID")}

	Clear-Host
	Write-Host "Logout complete"
}