function Invoke-HJLogout {
    $User = $($args[0] + "*")
    $ErrorActionPreference = "SilentlyContinue"
    
    ##Try to close the executables
    $pc = Get-WmiObject win32_serverconnection -ComputerName shea-2008r2 | Where-Object username -like $User
    $proc = Get-WmiObject -Class win32_process -Filter "name = 'HeavyJob.exe'" -computername $pc.ComputerName | Where-Object {$_.GetOwner().User -Like $User}
	$proc.Terminate()
	$proc = Get-WmiObject -Class win32_process -Filter "name = 'HeavyJob.exe'" -computername $pc.PSComputerName | Where-Object {$_.GetOwner().User -Like $User}
	$proc.Terminate()
     
    ##Enumerate left open files
    $FileList = Invoke-Expression "& C:\Windows\System32\openfiles.exe /query /s shea-2008r2 /fo CSV" | 
        ConvertFrom-Csv | Select-Object "ID","Accessed By","Open File (Path\executable)"

    $FilteredList = ($FileList | Where-Object {($_."Open File (Path\executable)" -Like "*heavyjob*" -and $_."Accessed By" -Like $User)} | Select-Object "ID")  
    
    ##Close open files on the file server
	$FilteredList | ForEach-Object {openfiles /disconnect /s shea-2008r2 /id $($_."ID")}

	Clear-Host
	Write-Host "Logout complete"
}