<#
.SYNOPSIS
Gets all custom baseline WAF test results for the last module runs and creates a summary.

.DESCRIPTION
This function will download the custom baseline WAF test results for the last module runs and create a summary.

.PARAMETER Repo
Mandatory. The name of the respository to scan. Needs to have the structure "<owner>/<repositioryName>", like 'Azure/bicep-registry-modules/'

.EXAMPLE
Get-WafTestCoverage -Repo 'owner/repo01'

Gets all custom baseline WAF test results for the last 100 workflow runs in the repository 'owner/repo01' that happened in the last 2 days.

.NOTES
Will be triggered by the workflow platform.get-waf-test-coverage.yml
#>
function Get-WafTestCoverage {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Repo
    )

    # ATTENTION: change to main branch when creating the PR
    $runId = gh run list --repo $repo --workflow 'platform.check.psrule.yml' --branch 'users/rahalan/BaselineCoverage3' --limit 1 --json 'databaseId' `
    | ConvertFrom-Json -Depth 100 `
    | Select-Object -ExpandProperty 'databaseId'

    gh run download $runId --repo $Repo

    $directory = Get-ChildItem -Filter 'avm-res-PSRule-output.csv' | Select-Object -Last 1
    $csv = Get-ChildItem -Path $directory.FullName

    if ($null -ne $csv) {
        $tests = Import-Csv -Path $csv.FullName

        if ($tests.Count -gt 0) {
            $tests `
            | Where-Object { $_.TargetType -ne 'Microsoft.Resources/deployments' -and $_.TargetType -ne 'Microsoft.Resources/deploymentScripts' } `
            | Select-Object -Property 'TargetType', 'RuleName', 'Outcome' -Unique `
            | Format-Table
        }
    }
}
