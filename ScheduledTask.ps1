$ServerFileName = "C:\Scripts\test\myservers.txt"
$ReportPath = "C:\Scripts\Test\"
$domainCred = "C:\Scripts\test\domainCred.XML"

$scriptFile = "HotFixReport.ps1 -ServerFileName $ServerFileName -ReportPath $ReportPath -DomainCredXMLFile $domainCred -SaveCreds -RunSilent"

$argumentList = "-executionpolicy bypass", "-mta", "-noninteractive", "-windowstyle normal", "-nologo", "-file $scriptFile"

# Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList $argumentList -NoNewWindow

.\HotFixReport.ps1 -ServerFileName $ServerFileName -ReportPath $ReportPath -DomainCredXMLFile $domainCred -SaveCreds -RunSilent