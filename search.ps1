param (
    [Parameter(Mandatory=$true)]
    [string]$SearchBaseDN,
    [Parameter(Mandatory=$true)]
    [string]$LdapFilter
)
$searcher = $null
$allResults = $null
try {
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = "LDAP://${SearchBaseDN}"
    $searcher.Filter = $LdapFilter
    $searcher.PageSize = 1000
    [void]$searcher.PropertiesToLoad.Add("distinguishedName")
    [void]$searcher.PropertiesToLoad.Add("objectClass")
    $allResults = $searcher.FindAll()
    if ($allResults.Count -gt 0) {
        Write-Host "Success! Found $($allResults.Count) object(s) matching filter '${LdapFilter}':"
        Write-Host "" 
        $count = 1
        foreach ($result in $allResults) {
            $dn = $result.Properties['distinguishedname'][0]
            $class = $result.Properties['objectclass'][-1]
            Write-Host "  $($count). Name: $dn"
            Write-Host "     Type: $class"
            Write-Host "     ----" 
            $count++
        }
    } else {
        Write-Host "No objects found matching filter '${LdapFilter}' in base DN '${SearchBaseDN}'."
    }
} catch {
    Write-Error "An error occurred during the LDAP search: $_"
} finally {
    if ($null -ne $allResults) {
        $allResults.Dispose()
    }
    if ($null -ne $searcher) {
        $searcher.Dispose()
    }
}
