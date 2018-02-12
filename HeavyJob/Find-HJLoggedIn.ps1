function Find-HJLoggedIn {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$True,
            HelpMessage="Please enter the file server's name that HeavyJob is hosted on::",
            Position=1
        )][string]$Server
    )
    
    ##Enumerate files open on the file server
	$FileList = Invoke-Expression "& C:\Windows\System32\openfiles.exe /query /s $Server /fo CSV" | ConvertFrom-Csv | Select-Object "ID","Accessed By","Open File (Path\executable)"

    ##Report each distinct Windows username holding file locks on anything with HeavyJob in the file path. 
    $FileList | Where-Object {$_."Open File (Path\executable)" -Like "*heavyjob*"}  | Select-Object "Accessed By"| Sort-Object -Property "Accessed By" -Unique
}