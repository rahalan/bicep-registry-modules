<#
.SYNOPSIS
Gets all custom baseline WAF test results for the last module runs and creates a summary.

.DESCRIPTION
This function will download the custom baseline WAF test results for the last module runs and create a summary.

.PARAMETER Repo
Mandatory. The name of the respository to scan. Needs to have the structure "<owner>/<repositioryName>", like 'Azure/bicep-registry-modules/'

.PARAMETER LimitNumberOfRuns
Optional. Number of recent runs to scan for failed runs. Default is 100.

.PARAMETER LimitInDays
Optional. Only runs in the past selected days will be analyzed. Default is 2.

.EXAMPLE
Get-WafTestCoverage -Repo 'owner/repo01' -LimitNumberOfRuns 100 -LimitInDays 2

Gets all custom baseline WAF test results for the last 100 workflow runs in the repository 'owner/repo01' that happened in the last 2 days.

.NOTES
Will be triggered by the workflow platform.get-waf-test-coverage.yml
#>
function Get-WafTestCoverage {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Repo,

        [Parameter(Mandatory = $false)]
        [int] $LimitNumberOfRuns = 100,

        [Parameter(Mandatory = $false)]
        [int] $LimitInDays = 2
    )

    $runs = gh run list --json 'number,name,databaseId,headBranch' --limit $LimitNumberOfRuns --repo $Repo | ConvertFrom-Json -Depth 100
    $uniqueRuns = @()
    # $runs | Where-Object { $_.headBranch -eq 'main' -and $_.name.StartsWith('avm.') } | Sort-Object -Property name, number -Descending | ForEach-Object {
    $runs | Where-Object { $_.headBranch -ne 'main' -and $_.name.StartsWith('avm.') } | Sort-Object -Property name, number -Descending | ForEach-Object {
        if ($uniqueRuns -notcontains $_.name) {
            $uniqueRuns += $_.name
            Write-Host "Downloading artifacts for run: $($_.name) $($_.databaseId)"
            gh run download $_.databaseId -p 'CB.AVM.WAF*' --repo $Repo
        }
    }

    $dir = Get-ChildItem -Filter 'CB.AVM.WAF*'
    $dir | ForEach-Object {
        $csv = Get-ChildItem -Path $_.FullName

        if ($null -ne $csv) {
            $tests = Import-Csv -Path $csv.FullName

            if ($tests.Count -gt 0) {
                Write-Host $_.Name
                $tests | Format-Table
            }
        }
    }
}
