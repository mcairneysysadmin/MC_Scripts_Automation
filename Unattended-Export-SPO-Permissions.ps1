param(
    [Parameter(Mandatory=$true)][string]$TenantId,          # Directory (tenant) ID GUID
    [Parameter(Mandatory=$true)][string]$AppId,             # App Registration (Client) ID
    [Parameter(Mandatory=$true)][string]$CertPath,          # Path to .pfx
    [Parameter(Mandatory=$true)][string]$CertPasswordPlain, # Password you set when exporting .pfx
    [Parameter(Mandatory=$true)][string]$TenantName,        # e.g. "tenantname"
    [Parameter()][string]$OutFolder = "C:\SPExport",
    [switch]$IncludeListPermissions
)

# Convert password
$CertPassword = ConvertTo-SecureString $CertPasswordPlain -AsPlainText -Force

# Build admin URL
$adminUrl = "https://$TenantName-admin.sharepoint.com"

Write-Host "Connecting to $adminUrl ..." -ForegroundColor Cyan
Connect-PnPOnline -Url $adminUrl `
    -ClientId $AppId `
    -Tenant $TenantId `
    -CertificatePath $CertPath `
    -CertificatePassword $CertPassword

# Ensure output folder exists
if (!(Test-Path -Path $OutFolder)) {
    New-Item -ItemType Directory -Path $OutFolder -Force | Out-Null
}

$sitesCsvPath     = Join-Path $OutFolder "SPOSites.csv"
$sitePermsCsvPath = Join-Path $OutFolder "SPOSitePermissions.csv"
$listPermsCsvPath = Join-Path $OutFolder "SPOListPermissions.csv"

# Get all site collections (excluding OneDrives)
Write-Host "Fetching site collections..." -ForegroundColor Cyan
$sites = Get-PnPTenantSite -Detailed

$sites | Select-Object Url, Title, Template, Owner, StorageQuota, StorageUsageCurrent, LastContentModifiedDate |
    Export-Csv -Path $sitesCsvPath -NoTypeInformation -Encoding UTF8

Write-Host "Found $($sites.Count) site collections. Exported overview to $sitesCsvPath" -ForegroundColor Green

$sitePerms = @()
$listPerms = @()

$counter = 0
foreach ($site in $sites) {
    $counter++
    Write-Host "[$counter/$($sites.Count)] Processing $($site.Url) ..." -ForegroundColor Yellow

    # Connect to each site
    Connect-PnPOnline -Url $site.Url `
        -ClientId $AppId `
        -Tenant $TenantId `
        -CertificatePath $CertPath `
        -CertificatePassword $CertPassword

    # Get groups and members
    $groups = Get-PnPGroup
    foreach ($g in $groups) {
        $members = Get-PnPGroupMember -Identity $g
        foreach ($m in $members) {
            $sitePerms += [PSCustomObject]@{
                SiteUrl     = $site.Url
                SiteTitle   = $site.Title
                PrincipalType = "GroupMember"
                GroupName   = $g.Title
                Principal   = $m.LoginName
                DisplayName = $m.Title
                Role        = ($g.Roles -join ";")
            }
        }
    }

    # Site users
    $users = Get-PnPUser
    foreach ($u in $users) {
        $sitePerms += [PSCustomObject]@{
            SiteUrl      = $site.Url
            SiteTitle    = $site.Title
            PrincipalType= "User"
            GroupName    = ""
            Principal    = $u.LoginName
            DisplayName  = $u.Title
            Role         = ""
        }
    }

    # Optional: Lists/libraries with broken inheritance
    if ($IncludeListPermissions) {
        $lists = Get-PnPList
        foreach ($list in $lists) {
            if ($list.HasUniqueRoleAssignments -eq $true) {
                # Pull groups for the list
                $groups = Get-PnPProperty -ClientObject $list -Property RoleAssignments
                foreach ($ra in $groups) {
                    $principal = $ra.Member.LoginName
                    $roles = ($ra.RoleDefinitionBindings | ForEach-Object { $_.Name }) -join ";"

                    $listPerms += [PSCustomObject]@{
                        SiteUrl     = $site.Url
                        SiteTitle   = $site.Title
                        ListTitle   = $list.Title
                        Principal   = $principal
                        DisplayName = $ra.Member.Title
                        Role        = $roles
                    }
                }
            }
        }
    }

    Start-Sleep -Milliseconds 300 # avoid throttling
}

# Export to CSV
$sitePerms | Export-Csv -Path $sitePermsCsvPath -NoTypeInformation -Encoding UTF8
if ($IncludeListPermissions) {
    $listPerms | Export-Csv -Path $listPermsCsvPath -NoTypeInformation -Encoding UTF8
}


Write-Host "Export complete! Outputs saved in $OutFolder" -ForegroundColor Green
