#######################################################################################################################################
#
#
#
#    Script: HotFix Reporting Script Include file
#    Author: Andy DeAngelis
#    Descrfiption: 
#         When adding new functions or modules for the main HotFixReport script to use, source/import them here.
#
#
#
#````Note: Powershellv3 or higher is needed.
#######################################################################################################################################

# Import the ImportExcel module, which can be downloaded from https://github.com/dfinke/ImportExcel.

Import-Module -Name "$PSScriptRoot\Modules\ImportExcel\ImportExcel.psm1" -Scope Local -PassThru


. "$PSScriptRoot\Functions\Get-IsAlive.ps1"
# . "$PSScriptRoot\Functions\Get-RebootHistory.ps1"
. "$PSScriptRoot\Functions\Test-TCPport.ps1"
