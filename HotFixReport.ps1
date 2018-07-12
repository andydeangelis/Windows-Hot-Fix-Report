<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	7/12/2018 11:10 AM
	 Created by:   	andy-user
	 Organization: 	
	 Filename:     	HotFixReport.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param (
	[parameter(Mandatory = $true, ValueFromPipeline = $True)]
	[string[]][string]$ServerFileName,
	[parameter(Mandatory = $false, ValueFromPipeline = $True)]
	[string]$ReportPath,
	[parameter(Mandatory = $false, ValueFromPipeline = $True)]
	[string]$DomainCredXMLFile,
	[parameter(Mandatory = $false, ValueFromPipeline = $false)]
	[switch]$SaveCreds = $false,
	[parameter(Mandatory = $false, ValueFromPipeline = $false)]
	[switch]$RunSilent = $false,
	[parameter(Mandatory = $false, ValueFromPipeline = $True)]
	[System.Management.Automation.PSCredential]$DomainCredentials
)

. $PSScriptRoot\IncludeMe.ps1

# Clear the error log.

# $Error.Clear()

# Add the required .NET assembly for Windows Forms.
Add-Type -AssemblyName System.Windows.Forms

if (-not $RunSilent)
{
	if ((-not $DomainCredentials) -and (-not $DomainCredXMLFile))
	{
		# Show the MsgBox. This is going to ask if the user needs to specify a separate Domain logon.
		$result = [System.Windows.Forms.MessageBox]::Show('Do you need to specify a separate Domain logon account?', 'Warning', 'YesNo', 'Warning')
		
		if ($result -eq 'Yes')
		{
			$domainCred = Get-Credential -Message "Please specify your domain name and password that has the rights to query WMI on the target servers."
		}
		else
		{
			Continue
		}
	}
	elseif ($DomainCredentials -and (-not $DomainCredXMLFile))
	{
		$domainCred = $DomainCredentials
	}
	elseif ((-not $DomainCredentials) -and $DomainCredXMLFile)
	{
		$domainCred = Import-Clixml -Path $DomainCredXMLFile
		if (-not $SaveCreds)
		{
			Remove-Item $DomainCredXMLFile -Force
		}
	}
	elseif ($DomainCredentials -and $DomainCredXMLFiles)
	{
		$domainCred = $DomainCredentials
	}
}
else
{
	if (-not $DomainCredXMLFile)
	{
		Write-Host "No Domain credential file found!" -ForegroundColor Red
		exit
	}
	else
	{
		$domainCred = Import-Clixml -Path $DomainCredXMLFile
	}
}

# Let's load the text file with the server names.

$servers = Get-Content $ServerFileName

# Now, let's make sure only unique names are listed.

$servers = $servers | select -Unique

# Get the system date to timestamp the files

$datetime = get-date -f MM-dd-yyyy_hh.mm.ss

# Check to see if the Reports Path variable is set. If not, set launch the folder browser dialog.

if (-not $ReportPath)
{
	# Create a dialog box to select the report target path.
	
	Add-Type -AssemblyName System.Windows.Forms
	$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
	$FolderBrowser.SelectedPath
	
	# If the report path is specified in the FolderBrowser, use that path. Otherwise, use the default path.
	
	if ($FolderBrowser.ShowDialog() -eq "OK")
	{
		$targetPath = $FolderBrowser.SelectedPath + "\HotFixInfo\$datetime"
	}
	else
	{
		$targetPath = "$PSScriptRoot\HotFixInfo\$datetime"
	}
}
else
{
	$targetPath = "$ReportPath\HotFixInfo\$datetime"
}

# Let's start our stopwatch.
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

$failedConnections = "$targetPath\FailedConnections-$datetime.txt"
$logFile = "$targetPath\DebugLogFile-$datetime.txt"

if (!(Test-Path $targetPath))
{
	New-Item -ItemType Directory -Force -Path $targetPath
}

if (!(Test-Path $logFile))
{
	New-Item -ItemType File -Force -Path $logFile
}

# Create a new, empty Excel document for SQL Data.
$HotFixInfoXlsxReportPath = "$targetPath\HotFixInfoReport-$datetime.xlsx"

Start-Transcript -Path $logFile

# Let's verify which servers are online and which are not.

if ($Servers -ne $null)
{
	$aliveServers = Get-IsAlive -ComputerNames $Servers
}

# Now, we use the Compare-Object cmdlet to get the list of servers that didn't respond to the Get-IsAlive function.

$deadServers = Compare-Object -ReferenceObject $aliveServers -DifferenceObject $Servers -PassThru

# Let's output the list of dead servers to the failed connection log.

$deadServers | Out-File -FilePath $failedConnections

foreach ($server in $aliveServers)
{
	$svrWorksheet = "$server"
	$svrTable = "$server"

	if ($server -eq $env:COMPUTERNAME)
	{
		$hotfixStatus = Get-HotFix -ComputerName $server | Select-Object PSComputerName, HotFixID, Description, InstalledBy, InstalledOn |
							Sort-Object -Property InstalledOn -Descending 
		
		$excel = $hotfixStatus | Export-Excel -Path $HotFixInfoXlsxReportPath -AutoSize -WorksheetName $svrWorksheet -FreezeTopRow -TableName $svrTable -PassThru
		$excel.Save(); $excel.Dispose()
	}
	else
	{
		$hotfixStatus = Get-HotFix -ComputerName $server -Credential $domainCred |
							Select-Object PSComputerName, HotFixID, Description, InstalledBy, InstalledOn |
							Sort-Object -Property InstalledOn -Descending
		
		$excel = $hotfixStatus | Export-Excel -Path $HotFixInfoXlsxReportPath -AutoSize -WorksheetName $svrWorksheet -FreezeTopRow -TableName $svrTable -PassThru
		$excel.Save(); $excel.Dispose()
	}
}

# Last, export the $Error variable to a log file.

# $Error | Out-File "$target\ErrorLog.log"

Write-Host "###############################################" -ForegroundColor DarkYellow
Write-Host "############ Report Locations #################" -ForegroundColor DarkYellow
Write-Host "###############################################" -ForegroundColor DarkYellow

Write-Host "The Transcript log file location:" -ForegroundColor Cyan -NoNewLine
Write-Host "$logFile." -ForegroundColor Yellow
Write-Host "The Failed Connections log file location:" -ForegroundColor Cyan -NoNewLine
Write-Host "$failedConnections" -ForegroundColor Yellow
Write-Host "The Hotfix Report file location:" -ForegroundColor Cyan -NoNewLine
Write-Host "$HotFixInfoXlsxReportPath" -ForegroundColor Yellow

Write-Host "###############################################" -ForegroundColor DarkYellow
Write-Host "############ Execution Times ##################" -ForegroundColor DarkYellow
Write-Host "###############################################" -ForegroundColor DarkYellow

Write-Host "The total number of Servers/Clusters checked is:" -ForegroundColor Cyan -NoNewline
Write-Host "$($servers.Count)" -ForegroundColor Yellow
Write-Host "The number of alive servers is:" -ForegroundColor Cyan -NoNewline
Write-Host "$($aliveServers.Count)" -ForegroundColor Yellow
Write-Host "The number of non-responsive servers is:" -ForegroundColor Cyan -NoNewline
Write-Host "$($deadServers.Count)" -ForegroundColor Yellow

$stopWatch.Stop()

Write-Host "Total script run time (ms): " -ForegroundColor Cyan -NoNewline
Write-Host "$($stopWatch.Elapsed.TotalMilliseconds)" -ForegroundColor Yellow

Write-Host "Total script run time (sec): " -ForegroundColor Cyan -NoNewline
Write-Host "$($stopWatch.Elapsed.TotalSeconds)" -ForegroundColor Yellow

Write-Host "Total script run time (min): " -ForegroundColor Cyan -NoNewline
Write-Host "$($stopWatch.Elapsed.TotalMinutes)" -ForegroundColor Yellow

Stop-Transcript

Write-Host "Data collection completed..."
