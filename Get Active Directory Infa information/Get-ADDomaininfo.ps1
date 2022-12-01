function Get-ADDomaininfo {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the domain, i.e. contoso.local")][string]$domain
    )
    
    #Test if specified domain is accessible
    if ($domain) {
        if (-not (Get-ADDomain -Identity $domain)) {
            Write-Warning ("Specified domain 0} is not accessible, please check spelling and access. Exiting..." -f $domain)
            return
        }
    }

    #Set $domain to current domain if not specified as parameter
    if (-not $domain) {
        $domain = (Get-ADDomain).dnsroot
    }

    #Gather overview of Domain Controllers
    $domainControllers = foreach ($domainController in (Get-ADDomain).ReplicaDirectoryServers) {
        $info = Get-ADDomainController -Identity $domainController
        [PSCustomObject]@{
            Name                    = $info.HostName
            IPv4Address             = $info.IPv4Address
            IPv6Address             = if ($info.IPv6Address)
            { $info.IPv6Address }
            else {
                "None"
            }
            "Certificate Authority" = if ((Get-WindowsFeature -ComputerName $DomainController -Name ADCS-Cert-Authority).InstallState -eq 'Installed') {
                "Installed"
            }
            else {
                "Not installed"
            }
            "DHCP Server"           = if ((Get-WindowsFeature -ComputerName $DomainController -Name DHCP).InstallState -eq 'Installed') {
                "Installed"
            }
            else {
                "Not installed"
            }
            "DNS Server"            = if ((Get-WindowsFeature -ComputerName $DomainController -Name DNS).InstallState -eq 'Installed') {
                "Installed"
            }
            else {
                "Not installed"
            }
            GlobalCatalog           = $info.IsGlobalCatalog
            "Operating System"      = $info.OperatingSystem
            FSMO                    = if ($info.OperationMasterRoles) {
                $info.OperationMasterRoles -join ", " 
            }
            else {
                "None"
            }
            Site                    = $info.Site
            OU                      = $info.ComputerObjectDN
        }
 
    }

    #Check for FSR configuration (https://kiwix.ounapuu.ee/serverfault.com_en_all_2019-02/A/question/876823.html)
    $searchFRS = New-Object DirectoryServices.DirectorySearcher
    $searchFRS.Filter = "(&(objectClass=nTFRSSubscriber)(name=Domain System Volume (SYSVOL share)))"
    $searchFRS.SearchRoot = $dcObjectPath
    
    #Gather Domain information
    $domainInfo = [PSCustomObject]@{
        "Active Directory Sites"       = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites.Name -join ", "
        "Active Directory Recycle Bin" = if ((Get-ADOptionalFeature -Filter 'Name -eq "Recycle Bin Feature"').EnabledScopes) {
            "Enabled"
        }
        else {
            "Not Enabled"
        }
        "Azure AD Connect Server(s)"   = if (Get-ADUser -LDAPFilter "(description=*configured to synchronize to tenant*)" -Properties description | ForEach-Object { $_.description.SubString(142, $_.description.IndexOf(" ", 142) - 142) }) {
            Get-ADUser -LDAPFilter "(description=*configured to synchronize to tenant*)" -Properties description | ForEach-Object { $_.description.SubString(142, $_.description.IndexOf(" ", 142) - 142) -join ", " }
        }
        else {
            "None"
        }
        "Domain Functional Level"      = (Get-ADDomain).DomainMode
        "Exchange Server(s)"           = if (Get-ADGroup -Filter { SamAccountName -eq "Exchange Servers" }) {
            (Get-ADGroupMember -Identity "Exchange Servers" | Where-Object ObjectClass -eq 'Computer').Name -join ", "
        }
        else {
            "None"
        }
        "Forest Functional Level"      = (Get-ADForest).ForestMode
        "FRS or DFSR for Sysvol"       = if ($searchFRS.FindAll().Count -eq '0') {
            "DFRS"
        }
        else {
            "FRS"
        }
        "Trusts"                       = if (Get-ADTrust -Filter *) {
            (Get-ADTrust -Filter *).Name -join ", "
        }
        else {
            "None"
        }
        "UPN Suffixes"                 = if ((Get-ADForest).UPNSuffixes) {
            (Get-ADForest).UPNSuffixes -join ", "
        }
        else {
            "None"
        }
    }   

    #Return all results
    return $domainControllers, $domainInfo
}