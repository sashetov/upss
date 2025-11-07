param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$groupDNs
)
function Get-ADObjectDetails {
    param ([string]$DistinguishedName)
    try {
        $entry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DistinguishedName")
        $name = $entry.Properties["name"].Value
        $objectClassValues = $entry.Properties["objectClass"].Value
        if ($objectClassValues -and $objectClassValues.Count -gt 0) {
            $class = $objectClassValues[-1]
        } else {
            $class = "unknown" 
        }
        return [PSCustomObject]@{
            Name    = $name
            Class   = $class
            DN      = $DistinguishedName
            IsGroup = ($class -eq "group")
        }
    } catch {
        Write-Warning "Could not retrieve details for: $DistinguishedName. Error: $($_)"
        return $null
    }
}
function Get-RecursiveGroupMembers {
    param (
        [string]$GroupDN,
        [System.Collections.Generic.HashSet[string]]$AllUserDNs, 
        [System.Collections.Generic.HashSet[string]]$ProcessedGroupDNs
    )
    if ($ProcessedGroupDNs.Contains($GroupDN)) {
        return 
    }
    $ProcessedGroupDNs.Add($GroupDN) | Out-Null
    try {
        $groupEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$GroupDN")
        $memberDNs = $groupEntry.Properties["member"]
        if (!$memberDNs) { return } 
        foreach ($memberDN in $memberDNs) {
            $details = Get-ADObjectDetails -DistinguishedName $memberDN
            if (!$details) { continue } 
            if ($details.IsGroup) {
                Get-RecursiveGroupMembers -GroupDN $details.DN -AllUserDNs $AllUserDNs -ProcessedGroupDNs $ProcessedGroupDNs
            } elseif ($details.Class -eq "user") {
                $AllUserDNs.Add($details.DN) | Out-Null
            }
        }
    } catch {
        Write-Warning "Error processing nested group ${GroupDN}: $($_)"
    }
}
foreach ($dn in $groupDNs) {
    $allUsersSet = New-Object System.Collections.Generic.HashSet[string]
    $processedGroupsSet = New-Object System.Collections.Generic.HashSet[string]
    try {
        $groupEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$dn")
        $groupName = $groupEntry.Properties["name"].Value
        Write-Host "=================================================================" -ForegroundColor Yellow
        Write-Host " Analyzing Group: $groupName" -ForegroundColor White
        Write-Host "=================================================================" -ForegroundColor Yellow
        Write-Host "Owner:" -ForegroundColor Cyan
        $ownerDN = $groupEntry.Properties["managedBy"].Value
        if ($ownerDN) {
            $ownerDetails = Get-ADObjectDetails -DistinguishedName $ownerDN
            if ($ownerDetails) {
                Write-Host "  - $($ownerDetails.Name) ($($ownerDetails.Class))"
                if ($ownerDetails.Class -eq "user") {
                    $allUsersSet.Add($ownerDetails.DN) | Out-Null
                }
            }
        } else {
            Write-Host "  - (Not set)"
        }
        Write-Host ""
        Get-RecursiveGroupMembers -GroupDN $dn -AllUserDNs $allUsersSet -ProcessedGroupDNs $processedGroupsSet
        Write-Host "All Unique Users (Recursive) ($($allUsersSet.Count)):" -ForegroundColor Cyan
        if ($allUsersSet.Count -gt 0) {
            $sortedUserNames = $allUsersSet | ForEach-Object { (Get-ADObjectDetails -DistinguishedName $_).Name } | Sort-Object
            foreach ($userName in $sortedUserNames) {
                Write-Host "  - $userName"
            }
        } else {
            Write-Host "  - (No users found in this group or its subgroups)"
        }
        Write-Host ""
    } catch {
        Write-Warning "Could not process top-level group: ${dn}. Error: $($_)"
        Write-Host ""
    }
}
