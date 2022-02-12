[CmdletBinding()]
param()

Write-Verbose -Message 'Installing required dependencies...'
. $PSScriptRoot\tools\install.ps1

# TODO: Create a psd1 manifest with all properties properly referenced

# TODO: Pester tests
