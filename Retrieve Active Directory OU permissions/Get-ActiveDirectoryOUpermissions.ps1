function Get-ActiveDirectoryOUpermissions {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the path to where the CSV file should be stored, e.g c:\temp\OU_ACL.csv")][string]$Output,
        [Parameter(Mandatory = $false, HelpMessage = "Start OU to scan including child OU's, format it like 'OU=Servers,DC=domain,DC=Local'")][string]$StartOU
    )

    #Validate output by creating the file, stop if location is inaccessible
    try {
        New-Item -Path $Output -ItemType File -Force:$true -ErrorAction Stop | Out-Null
        Write-Host ("Output to {0} is valid" -f $Output) -ForegroundColor Green
    }
    catch {
        Write-Warning ("The output can't be saved as {0}, is specified path accessible?" -f $Output)
        break
    }

    #Try to detect the Active Directory Domain name before continuing and stop script if it fails
    try {
        $domain = (Get-ADDomain -ErrorAction Stop).DNSroot
        Write-Host ('Domain {0} detected' -f $domain) -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not retrieve Domain Name, is the ActiveDirectory module installed or are you running this from a non-domain-joined device?"
        break
    }

    #Continu if Active Directory Domain was detected and retrieve list of OU's from the whole domain
    #or from the Ou specified in the StartOU parameter
    if ($domain) {
        if ($StartOU) {
            try {
                Write-Host ("Retrieving OU's for Domain {0} starting from {1}" -f $domain, $StartOU) -ForegroundColor Green
                $oulist = Get-ADOrganizationalUnit -SearchBase $StartOU -Filter * -ResultSetSize 10000 -SearchScope Subtree -ErrorAction Stop | Sort-Object DistinguishedName
            }
            catch {
                Write-Warning ("Could not use {0}, check spelling and format it like 'OU=Servers,DC=domain,DC=Local')" -f $startou)
                break
            }
        }
        else {
            Write-Host ("Retrieving all OU's for Domain {0}" -f $domain, $StartOU) -ForegroundColor Green
            $oulist = Get-ADOrganizationalUnit -Filter * -ResultSetSize 10000 -SearchScope Subtree -ErrorAction Stop | Sort-Object DistinguishedName
        }
    }
    
    #Function for translating ObjectTypes to name
    #Thanks go out for the blog here https://blog.wobl.it/2016/04/active-directory-guid-to-friendly-name-using-just-powershell/
    function Get-NameForGUID {
        [CmdletBinding()]
        Param(
            [guid]$guid
        )
        Begin {
            $DomainDC = ([ADSI]"").distinguishedName
            $ExtendedRightGUIDs = "LDAP://cn=Extended-Rights,cn=configuration,$DomainDC"
            $PropertyGUIDs = "LDAP://cn=schema,cn=configuration,$DomainDC"
        }
        Process {
            If ($guid -eq "00000000-0000-0000-0000-000000000000") {
                Return "All"
            }
            Else {
                $rightsGuid = $guid
                $property = "cn"
                $SearchAdsi = ([ADSISEARCHER]"(rightsGuid=$rightsGuid)")
                $SearchAdsi.SearchRoot = $ExtendedRightGUIDs
                $SearchAdsi.SearchScope = "OneLevel"
                $SearchAdsiRes = $SearchAdsi.FindOne()
                If ($SearchAdsiRes) {
                    Return $SearchAdsiRes.Properties[$property]
                }
                Else {
                    $SchemaGuid = $guid
                    $SchemaByteString = "\" + ((([guid]$SchemaGuid).ToByteArray() | ForEach-Object { $_.ToString("x2") }) -Join "\")
                    $property = "ldapDisplayName"
                    $SearchAdsi = ([ADSISEARCHER]"(schemaIDGUID=$SchemaByteString)")
                    $SearchAdsi.SearchRoot = $PropertyGUIDs
                    $SearchAdsi.SearchScope = "OneLevel"
                    $SearchAdsiRes = $SearchAdsi.FindOne()
                    If ($SearchAdsiRes) {
                        Return $SearchAdsiRes.Properties[$property]
                    }
                    Else {
                        Return $guid.ToString()
                    }
                }
            }
        }
    }

    #Custom object for certain Security Identifiers which don't report a friendly name
    #List is from https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/security-identifiers
    $customidentifiers = @{
        'S-1-5-32-544' = 'Administrators'
        'S-1-5-32-545' = 'Users'
        'S-1-5-32-546' = 'Guests'
        'S-1-5-32-547' = 'Power Users'
        'S-1-5-32-548' = 'Account Operators'
        'S-1-5-32-549' = 'Server Operators'
        'S-1-5-32-550' = 'Print Operators'
        'S-1-5-32-551' = 'Backup Operators'
        'S-1-5-32-552' = 'Replicators'
        'S-1-5-32-554' = 'Builtin\Pre-Windows 2000 Compatible Access'
        'S-1-5-32-555' = 'Builtin\Remote Desktop Users'
        'S-1-5-32-556' = 'Builtin\Network Configuration Operators'
        'S-1-5-32-557' = 'Builtin\Incoming Forest Trust Builders'
        'S-1-5-32-558' = 'Builtin\Performance Monitor Users'
        'S-1-5-32-559' = 'Builtin\Performance Log Users'
        'S-1-5-32-560' = 'Builtin\Windows Authorization Access Group'
        'S-1-5-32-561' = 'Builtin\Terminal Server License Servers'
        'S-1-5-32-562' = 'Builtin\Distributed COM Users'
        'S-1-5-32-568' = 'Builtin\IIS_IUSRS'
        'S-1-5-32-569' = 'Builtin\Cryptographic Operators'
        'S-1-5-32-573' = 'Builtin\Event Log Readers'
        'S-1-5-32-574' = 'Builtin\Certificate Service DCOM Access'
        'S-1-5-32-575' = 'Builtin\RDS Remote Access Servers'
        'S-1-5-32-576' = 'Builtin\RDS Endpoint Servers'
        'S-1-5-32-577' = 'Builtin\RDS Management Servers'
        'S-1-5-32-578' = 'Builtin\Hyper-V Administrators'
        'S-1-5-32-579' = 'Builtin\Access Control Assistance Operators'
        'S-1-5-32-580' = 'Builtin\Remote Management Users'
    }

    #Create empty variable acltotal, loop through all OU's and save the ACL's to $acltotal
    $acltotal = @()
    foreach ($ou in $oulist) {
        Write-Host ("Processing {0}" -f $ou.DistinguishedName) -ForegroundColor Green
        $acls = (Get-Acl -path "AD:$($ou.DistinguishedName)").Access
        foreach ($acl in $acls) {            
            #If IdentityReference matches item in $customidentifiers, change it to the friendly name
            #Otherwise just use the IdentityReference found by Get-Acl
            if ($customidentifiers | Select-string "$($acl.IdentityReference.Value)" -SimpleMatch ) {
                $IdentityReference = ($customidentifiers | Select-Object -Property $acl.IdentityReference.Value).$($acl.IdentityReference.Value)
            }
            else {
                $IdentityReference = "$($acl.IdentityReference)"
            }

            Write-Host ("- Retrieving {0} details for {1}" -f $acl.ActiveDirectoryRights, $IdentityReference) -ForegroundColor Gray

            $foundacls = [PSCustomObject]@{
                OrganizationalUnit = $ou.DistinguishedName
                Principal          = $IdentityReference
                Rights             = $acl.ActiveDirectoryRights
                AppliesTo          = Get-NameForGUID $acl.InheritedObjectType
                Item               = Get-NameForGUID $acl.ObjectType
                Access             = $acl.AccessControlType
                Inheritance        = $acl.InheritanceType
                InheritanceFrom    = $acl.InheritanceFlags
            }
            $acltotal += $foundacls
        }
    }

    #Export results to CSV file
    if ($acltotal.count -gt 0) {
        Write-Host ("Exporting {0} results to {1}" -f $acltotal.count, $Output) -ForegroundColor Green
        $acltotal | Sort-Object OrganizationalUnit, Principal, Rights, AppliesTo, Item, Access, Inheritance, InheritanceFrom | Export-Csv -Path $Output -Encoding UTF8 -Delimiter ';' -NoTypeInformation
    }
}
