param (
    [Parameter(Mandatory=$true)]
    [string]$ManagerUsername,
    [Parameter(Mandatory=$true)]
    [string]$SearchBaseDN
)
$SearchRoot = [ADSI]"LDAP://$SearchBaseDN"
function Get-RecursiveReports {
    param (
        [string]$ManagerDN,
        [string]$Indent = "  "
    )
    $reportsSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $reportsSearcher.SearchRoot = $SearchRoot
    $reportsSearcher.Filter = "(&(objectClass=user)(manager=$ManagerDN)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
    $reportsSearcher.PropertiesToLoad.Add("name")
    $reportsSearcher.PropertiesToLoad.Add("sAMAccountName")
    $reportsSearcher.PropertiesToLoad.Add("distinguishedName")
    $null = $reportsSearcher.PropertiesToLoad
    $reportsSearcher.PageSize = 1000
    try {
        $directReports = $reportsSearcher.FindAll()
        foreach ($report in $directReports) {
            $reportName = $report.Properties["name"][0]
            $reportUsername = $report.Properties["samaccountname"][0]
            $reportDN = $report.Properties["distinguishedname"][0]
            Write-Host "$Indent- $reportName ($reportUsername)" -ForegroundColor Cyan
            Get-RecursiveReports -ManagerDN $reportDN -Indent "$Indent  "
        }
    }
    catch {
        Write-Warning "Error searching for reports of ${ManagerDN}: $_"
    }
    finally {
        $reportsSearcher.Dispose()
    }
}
Write-Host "Searching for root manager '$ManagerUsername'..." -ForegroundColor Gray
$managerSearcher = New-Object System.DirectoryServices.DirectorySearcher
$managerSearcher.SearchRoot = $SearchRoot
$managerSearcher.Filter = "(&(|(sAMAccountName=$ManagerUsername)(userPrincipalName=$ManagerUsername))(objectClass=user))"
$managerSearcher.PropertiesToLoad.Add("distinguishedName")
$managerSearcher.PropertiesToLoad.Add("name")
$null = $managerSearcher.PropertiesToLoad
$managerResult = $managerSearcher.FindOne()
if (!$managerResult) {
    Write-Error "Could not find a user with username '$ManagerUsername' in $SearchBaseDN."
    $managerSearcher.Dispose()
    return
}
$managerDN = $managerResult.Properties["distinguishedname"][0]
$managerName = $managerResult.Properties["name"][0]
Write-Host "=================================================================" -ForegroundColor Yellow
Write-Host " Finding All Reports Under: $managerName ($ManagerUsername)" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Yellow
Write-Host "$managerName ($ManagerUsername)" -ForegroundColor Yellow
Get-RecursiveReports -ManagerDN $managerDN
$managerSearcher.Dispose()
