[CmdletBinding(DefaultParameterSetName = "Folder")]
param(
    [parameter(Mandatory = $true, HelpMessage = "Specify filename to scan, e.g. c:\scripts\azure.ps1", parameterSetname = "File")][string]$Filename,
    [parameter(Mandatory = $true, HelpMessage = "Specify folder to scan, e.g. c:\scripts", parameterSetname = "Folder")][string]$Folder,
    [parameter(Mandatory = $false, HelpMessage = "Specify csv or xlsx report filename, e.g. c:\temp\report.xlsx")][string]$OutFile
)
#Below Cmdlets and their replacements were retrieved from
#https://learn.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0&pivots=azure-ad-powershell
$Commands = @{
    'Add-AzureADAdministrativeUnitMember'                               = 'New-MgDirectoryAdministrativeUnitMember'
    'Add-AzureADApplicationOwner'                                       = 'New-MgApplicationOwnerByRef'
    'Add-AzureADApplicationPolicy'                                      = 'New-MgApplicationAppManagementPolicyByRef'
    'Add-AzureADDeviceRegisteredOwner'                                  = 'New-MgDeviceRegisteredOwnerByRef'
    'Add-AzureADDeviceRegisteredUser'                                   = 'New-MgDeviceRegisteredUserByRef'
    'Add-AzureADDirectoryRoleMember'                                    = 'New-MgDirectoryRoleMemberByRef'
    'Add-AzureADGroupMember'                                            = 'New-MgGroupMemberByRef'
    'Add-AzureADGroupOwner'                                             = 'New-MgGroupOwnerByRef'
    'Add-AzureADMSAdministrativeUnitMember'                             = 'New-MgDirectoryAdministrativeUnitMemberByRef'
    'Add-AzureADMSApplicationOwner'                                     = 'New-MgApplicationOwnerByRef'
    'Add-AzureADMSCustomSecurityAttributeDefinitionAllowedValues'       = 'New-MgDirectoryCustomSecurityAttributeDefinitionAllowedValue'
    'Add-AzureADMSFeatureRolloutPolicyDirectoryObject'                  = 'New-MgBetaDirectoryFeatureRolloutPolicyApplyToByRef'
    'Add-AzureADMSLifecyclePolicyGroup'                                 = 'Add-MgGroupToLifecyclePolicy'
    'Add-AzureADMSPrivilegedResource'                                   = 'Deprecated'
    'Add-AzureADMSScopedRoleMembership'                                 = 'New-MgDirectoryRoleScopedMember'
    'Add-AzureADMSServicePrincipalDelegatedPermissionClassification'    = 'New-MgServicePrincipalDelegatedPermissionClassification'
    'Add-AzureADScopedRoleMembership'                                   = 'New-MgDirectoryAdministrativeUnitScopedRoleMember'
    'Add-AzureADServicePrincipalOwner'                                  = 'New-MgServicePrincipalOwnerByRef'
    'Add-AzureADServicePrincipalPolicy'                                 = 'New-MgServicePrincipalClaimMappingPolicyByRef'
    'Add-MsolAdministrativeUnitMember'                                  = 'New-MgDirectoryAdministrativeUnitMemberByRef'
    'Add-MsolForeignGroupToRole'                                        = 'N.A.'
    'Add-MsolGroupMember'                                               = 'New-MgGroupMemberByRef'
    'Add-MsolRoleMember'                                                = 'New-MgDirectoryRoleMemberByRef'
    'Add-MsolScopedRoleMember'                                          = 'New-MgDirectoryRoleScopedMember'
    'Close-AzureADMSPrivilegedRoleAssignmentRequest'                    = 'Deprecated'
    'Confirm-AzureADDomain'                                             = 'Confirm-MgDomain'
    'Confirm-MsolDomain'                                                = 'Confirm-MgDomain'
    'Confirm-MsolEmailVerifiedDomain'                                   = 'N.A.'
    'Connect-AzureAD'                                                   = 'Connect-MgGraph'
    'Connect-MsolService'                                               = 'Connect-MgGraph'
    'Convert-MsolDomainToFederated'                                     = 'New-MgDomainFederationConfiguration'
    'Convert-MsolDomainToStandard'                                      = 'Remove-MgDomainFederationConfiguration'
    'Convert-MsolFederatedUser'                                         = 'Reset-MgUserAuthenticationMethodPassword'
    'Disable-MsolDevice'                                                = 'Update-MgDevice'
    'Disconnect-AzureAD'                                                = 'Disconnect-MgGraph'
    'Enable-AzureADDirectoryRole'                                       = 'New-MgDirectoryRole'
    'Enable-MsolDevice'                                                 = 'Update-MgDevice'
    'Get-AzureADAdministrativeUnit'                                     = 'Get-MgDirectoryAdministrativeUnit'
    'Get-AzureADAdministrativeUnitMember'                               = 'Get-MgDirectoryAdministrativeUnitMember'
    'Get-AzureADApplication'                                            = 'Get-MgApplication'
    'Get-AzureADApplicationExtensionProperty'                           = 'Get-MgApplicationExtensionProperty'
    'Get-AzureADApplicationKeyCredential'                               = 'Get-MgApplication'
    'Get-AzureADApplicationLogo'                                        = 'Get-MgApplicationLogo'
    'Get-AzureADApplicationOwner'                                       = 'Get-MgApplicationOwner'
    'Get-AzureADApplicationPasswordCredential'                          = 'Get-MgApplication'
    'Get-AzureADApplicationPolicy'                                      = 'Get-MgApplicationAppManagementPolicyByRef'
    'Get-AzureADApplicationProxyApplication'                            = 'Get-MgBetaApplication'
    'Get-AzureADApplicationProxyApplicationConnectorGroup'              = 'N.A.'
    'Get-AzureADApplicationProxyConnector'                              = 'Get-MgBetaOnPremisePublishingProfileConnector'
    'Get-AzureADApplicationProxyConnectorGroup'                         = 'Get-MgBetaOnPremisePublishingProfileConnectorGroup'
    'Get-AzureADApplicationProxyConnectorGroupMember'                   = 'N.A.'
    'Get-AzureADApplicationProxyConnectorGroupMembers'                  = 'Get-MgBetaOnPremisePublishingProfileConnectorGroupMember'
    'Get-AzureADApplicationProxyConnectorMemberOf'                      = 'Get-MgBetaOnPremisePublishingProfileConnectorMemberOf'
    'Get-AzureADApplicationServiceEndpoint'                             = 'Get-MgServicePrincipalEndpoint'
    'Get-AzureADApplicationSignInDetailedSummary'                       = 'Get-MgBetaReportApplicationSignInDetailedSummary'
    'Get-AzureADApplicationSignInSummary'                               = 'Get-MgBetaReportAzureAdApplicationSignInSummary'
    'Get-AzureADAuditDirectoryLogs'                                     = 'Get-MgAuditLogDirectoryAudit'
    'Get-AzureADAuditSignInLogs'                                        = 'Get-MgAuditLogSignIn'
    'Get-AzureADContact'                                                = 'Get-MgContact'
    'Get-AzureADContactDirectReport'                                    = 'Get-MgContactDirectReport'
    'Get-AzureADContactManager'                                         = 'Get-MgContactManager'
    'Get-AzureADContactMembership'                                      = 'Get-MgContactMemberOf'
    'Get-AzureADContract'                                               = 'Get-MgContract'
    'Get-AzureADCurrentSessionInfo'                                     = 'Get-MgContext'
    'Get-AzureADDeletedApplication'                                     = 'Get-MgDirectoryDeletedItem'
    'Get-AzureADDevice'                                                 = 'Get-MgDevice'
    'Get-AzureADDeviceConfiguration'                                    = 'Get-MgDeviceManagementDeviceConfiguration'
    'Get-AzureADDeviceRegisteredOwner'                                  = 'Get-MgDeviceRegisteredOwner'
    'Get-AzureADDeviceRegisteredUser'                                   = 'Get-MgDeviceRegisteredUser'
    'Get-AzureADDirectoryRole'                                          = 'Get-MgDirectoryRole'
    'Get-AzureADDirectoryRoleMember'                                    = 'Get-MgDirectoryRoleMember'
    'Get-AzureADDirectoryRoleTemplate'                                  = 'Get-MgDirectoryRoleTemplate'
    'Get-AzureADDirectorySetting'                                       = 'Get-MgBetaDirectorySetting'
    'Get-AzureADDirectorySettingTemplate'                               = 'Get-MgBetaDirectorySettingTemplate'
    'Get-AzureADDomain'                                                 = 'Get-MgDomain'
    'Get-AzureADDomainNameReference'                                    = 'Get-MgDomainNameReference'
    'Get-AzureADDomainServiceConfigurationRecord'                       = 'Get-MgDomainServiceConfigurationRecord'
    'Get-AzureADDomainVerificationDnsRecord'                            = 'Get-MgDomainVerificationDnsRecord'
    'Get-AzureADExtensionProperty'                                      = 'Get-MgDirectoryObjectAvailableExtensionProperty'
    'Get-AzureADExternalDomainFederation'                               = 'Get-MgDomainFederationConfiguration'
    'Get-AzureADGroup'                                                  = 'Get-MgGroup'
    'Get-AzureADGroupAppRoleAssignment'                                 = 'Get-MgGroupAppRoleAssignment'
    'Get-AzureADGroupMember'                                            = 'Get-MgGroupMember'
    'Get-AzureADGroupOwner'                                             = 'Get-MgGroupOwner'
    'Get-AzureADMSAdministrativeUnit'                                   = 'Get-MgDirectoryAdministrativeUnit'
    'Get-AzureADMSAdministrativeUnitMember'                             = 'Get-MgDirectoryAdministrativeUnitMember'
    'Get-AzureADMSApplication'                                          = 'Get-MgApplication'
    'Get-AzureADMSApplicationExtensionProperty'                         = 'Get-MgApplicationExtensionProperty'
    'Get-AzureADMSApplicationOwner'                                     = 'Get-MgApplicationOwner'
    'Get-AzureADMSApplicationTemplate'                                  = 'Get-MgApplicationTemplate'
    'Get-AzureADMSAttributeSet'                                         = 'Get-MgDirectoryAttributeSet'
    'Get-AzureADMSAuthorizationPolicy'                                  = 'Get-MgPolicyAuthorizationPolicy'
    'Get-AzureADMSConditionalAccessPolicy'                              = 'Get-MgIdentityConditionalAccessPolicy'
    'Get-AzureADMSCustomSecurityAttributeDefinition'                    = 'Get-MgDirectoryCustomSecurityAttributeDefinition'
    'Get-AzureADMSCustomSecurityAttributeDefinitionAllowedValue'        = 'Get-MgDirectoryCustomSecurityAttributeDefinitionAllowedValue'
    'Get-AzureADMSDeletedDirectoryObject'                               = 'Get-MgDirectoryDeletedItem'
    'Get-AzureADMSDeletedGroup'                                         = 'Get-MgDirectoryDeletedItem'
    'Get-AzureADMSFeatureRolloutPolicy'                                 = 'Get-MgPolicyFeatureRolloutPolicy'
    'Get-AzureADMSGroup'                                                = 'Get-MgGroup'
    'Get-AzureADMSGroupLifecyclePolicy'                                 = 'Get-MgGroupLifecyclePolicy'
    'Get-AzureADMSGroupPermissionGrant'                                 = 'Get-MgGroupPermissionGrant'
    'Get-AzureADMSIdentityProvider'                                     = 'Get-MgIdentityProvider'
    'Get-AzureADMSLifecyclePolicyGroup'                                 = 'Get-MgGroupLifecyclePolicy'
    'Get-AzureADMSNamedLocationPolicy'                                  = 'Get-MgIdentityConditionalAccessNamedLocation'
    'Get-AzureADMSPasswordSingleSignOnCredential'                       = 'Get-MgBetaServicePrincipalPasswordSingleSignOnCredential'
    'Get-AzureADMSPermissionGrantConditionSet'                          = 'Get-MgPolicyPermissionGrantPolicyInclude'
    'Get-AzureADMSPermissionGrantPolicy'                                = 'Get-MgPolicyPermissionGrantPolicy'
    'Get-AzureADMSPrivilegedResource'                                   = 'Get-MgBetaPrivilegedAccessResource'
    'Get-AzureADMSPrivilegedRoleAssignment'                             = 'Deprecated'
    'Get-AzureADMSPrivilegedRoleAssignmentRequest'                      = 'Deprecated'
    'Get-AzureADMSPrivilegedRoleDefinition'                             = 'Get-MgBetaPrivilegedAccessResourceRoleDefinition'
    'Get-AzureADMSPrivilegedRoleSetting'                                = 'Get-MgBetaPrivilegedAccessResourceRoleSetting'
    'Get-AzureADMSRoleAssignment'                                       = 'Get-MgRoleManagementDirectoryRoleAssignment'
    'Get-AzureADMSRoleDefinition'                                       = 'Get-MgRoleManagementDirectoryRoleDefinition'
    'Get-AzureADMSScopedRoleMembership'                                 = 'Get-MgUserScopedRoleMemberOf'
    'Get-AzureADMSServicePrincipal'                                     = 'Get-MgServicePrincipal'
    'Get-AzureADMSServicePrincipalDelegatedPermissionClassification'    = 'Get-MgServicePrincipalDelegatedPermissionClassification'
    'Get-AzureADMSTrustFrameworkPolicy'                                 = 'Get-MgBetaTrustFrameworkPolicy'
    'Get-AzureADMSUser'                                                 = 'Get-MgUser'
    'Get-AzureADOAuth2PermissionGrant'                                  = 'Get-MgOauth2PermissionGrant'
    'Get-AzureADObjectByObjectId'                                       = 'Get-MgDirectoryObjectById'
    'Get-AzureADObjectSetting'                                          = 'Get-MgGroupSetting'
    'Get-AzureADPolicy'                                                 = 'Get-MgPolicyHomeRealmDiscoveryPolicy,Get-MgPolicyActivityBasedTimeoutPolicy,Get-MgPolicyTokenIssuancePolicy,Get-MgPolicyTokenLifetimePolicy,Get-MgPolicyClaimMappingPolicy'
    'Get-AzureADPolicyAppliedObject'                                    = 'Get-MgPolicyHomeRealmDiscoveryPolicyApplyTo'
    'Get-AzureADPrivilegedRole'                                         = 'Deprecated'
    'Get-AzureADPrivilegedRoleAssignment'                               = 'Get-MgBetaPrivilegedRoleRoleAssignment'
    'Get-AzureADScopedRoleMembership'                                   = 'Get-MgDirectoryAdministrativeUnitScopedRoleMember'
    'Get-AzureADServiceAppRoleAssignedTo'                               = 'Get-MgServicePrincipalAppRoleAssignedTo'
    'Get-AzureADServiceAppRoleAssignment'                               = 'Get-MgServicePrincipalAppRoleAssignment'
    'Get-AzureADServicePrincipal'                                       = 'Get-MgServicePrincipal'
    'Get-AzureADServicePrincipalCreatedObject'                          = 'Get-MgServicePrincipalCreatedObject'
    'Get-AzureADServicePrincipalKeyCredential'                          = 'Get-MgServicePrincipal'
    'Get-AzureADServicePrincipalMembership'                             = 'Get-MgServicePrincipalTransitiveMemberOf'
    'Get-AzureADServicePrincipalOAuth2PermissionGrant'                  = 'Get-MgServicePrincipalOauth2PermissionGrant'
    'Get-AzureADServicePrincipalOwnedObject'                            = 'Get-MgServicePrincipalOwnedObject'
    'Get-AzureADServicePrincipalOwner'                                  = 'Get-MgServicePrincipalOwner'
    'Get-AzureADServicePrincipalPasswordCredential'                     = 'Get-MgServicePrincipal'
    'Get-AzureADServicePrincipalPolicy'                                 = 'Get-MgServicePrincipalClaimMappingPolicy,Get-MgServicePrincipalHomeRealmDiscoveryPolicy,Get-MgServicePrincipalTokenIssuancePolicy,Get-MgServicePrincipalTokenLifetimePolicy'
    'Get-AzureADSubscribedSku'                                          = 'Get-MgSubscribedSku'
    'Get-AzureADTenantDetail'                                           = 'Get-MgOrganization'
    'Get-AzureADTrustedCertificateAuthority'                            = 'Get-MgOrganizationCertificateBasedAuthConfiguration'
    'Get-AzureADUser'                                                   = 'Get-MgUser'
    'Get-AzureADUserAppRoleAssignment'                                  = 'Get-MgUserAppRoleAssignment'
    'Get-AzureADUserCreatedObject'                                      = 'Get-MgUserCreatedObject'
    'Get-AzureADUserDirectReport'                                       = 'Get-MgUserDirectReport'
    'Get-AzureADUserExtension'                                          = 'Get-MgUser'
    'Get-AzureADUserLicenseDetail'                                      = 'Get-MgUserLicenseDetail'
    'Get-AzureADUserManager'                                            = 'Get-MgUserManager'
    'Get-AzureADUserMembership'                                         = 'Get-MgUserMemberOf'
    'Get-AzureADUserOAuth2PermissionGrant'                              = 'Get-MgUserOauth2PermissionGrant'
    'Get-AzureADUserOwnedDevice'                                        = 'Get-MgUserOwnedDevice'
    'Get-AzureADUserOwnedObject'                                        = 'Get-MgUserOwnedObject'
    'Get-AzureADUserRegisteredDevice'                                   = 'Get-MgUserRegisteredDevice'
    'Get-AzureADUserThumbnailPhoto'                                     = 'Get-MgUserPhoto'
    'Get-CrossCloudVerificationCode'                                    = 'Confirm-MgDomain'
    'Get-MsolAccountSku'                                                = 'Get-MgSubscribedSku'
    'Get-MsolAdministrativeUnit'                                        = 'Get-MgDirectoryAdministrativeUnit'
    'Get-MsolAdministrativeUnitMember'                                  = 'Get-MgDirectoryAdministrativeUnitMember'
    'Get-MsolCompanyAllowedDataLocation'                                = 'N.A.'
    'Get-MsolCompanyInformation'                                        = 'Get-MgOrganization'
    'Get-MsolContact'                                                   = 'Get-MgContact'
    'Get-MsolDevice'                                                    = 'Get-MgDevice'
    'Get-MsolDeviceRegistrationServicePolicy'                           = 'Get-MgPolicyDeviceRegistrationPolicy'
    'Get-MsolDirSyncConfiguration'                                      = 'Get-MgDirectoryOnPremiseSynchronization'
    'Get-MsolDirSyncFeatures'                                           = 'Get-MgDirectoryOnPremiseSynchronization'
    'Get-MsolDirSyncProvisioningError'                                  = 'N.A.'
    'Get-MsolDomain'                                                    = 'Get-MgDomain'
    'Get-MsolDomainFederationSettings'                                  = 'Get-MgDomainFederationConfiguration'
    'Get-MsolDomainVerificationDns'                                     = 'Get-MgDomainVerificationDnsRecord'
    'Get-MsolFederationProperty'                                        = 'Get-MgDomainFederationConfiguration'
    'Get-MsolGroup'                                                     = 'Get-MgGroup'
    'Get-MsolGroupMember'                                               = 'Get-MgGroupMember'
    'Get-MsolHasObjectsWithDirSyncProvisioningErrors'                   = 'N.A.'
    'Get-MsolPartnerContract'                                           = 'Get-MgContract'
    'Get-MsolPartnerInformation'                                        = 'N.A.'
    'Get-MsolPasswordPolicy'                                            = 'Get-MgDomain'
    'Get-MsolRole'                                                      = 'Get-MgDirectoryRole'
    'Get-MsolRoleMember'                                                = 'Get-MgDirectoryRoleMember'
    'Get-MsolScopedRoleMember'                                          = 'Get-MgDirectoryRoleScopedMember'
    'Get-MsolServicePrincipal'                                          = 'Get-MgServicePrincipal'
    'Get-MsolServicePrincipalCredential'                                = 'Get-MgServicePrincipal'
    'Get-MsolSubscription'                                              = 'Get-MgDirectorySubscription'
    'Get-MsolUser'                                                      = 'Get-MgUser'
    'Get-MsolUserByStrongAuthentication'                                = 'N.A.'
    'Get-MsolUserRole'                                                  = 'Get-MgUserMemberOf'
    'New-AzureADAdministrativeUnit'                                     = 'New-MgDirectoryAdministrativeUnit'
    'New-AzureADApplication'                                            = 'New-MgApplication'
    'New-AzureADApplicationExtensionProperty'                           = 'New-MgApplicationExtensionProperty'
    'New-AzureADApplicationKeyCredential'                               = 'Add-MgApplicationKey'
    'New-AzureADApplicationPasswordCredential'                          = 'Add-MgApplicationPassword'
    'New-AzureADApplicationProxyApplication'                            = 'N.A.'
    'New-AzureADApplicationProxyConnectorGroup'                         = 'New-MgBetaOnPremisePublishingProfileConnectorGroup'
    'New-AzureADDevice'                                                 = 'New-MgDevice'
    'New-AzureADDirectorySetting'                                       = 'New-MgBetaDirectorySetting'
    'New-AzureADDomain'                                                 = 'New-MgDomain'
    'New-AzureADExternalDomainFederation'                               = 'New-MgDomainFederationConfiguration'
    'New-AzureADGroup'                                                  = 'New-MgGroup'
    'New-AzureADGroupAppRoleAssignment'                                 = 'New-MgGroupAppRoleAssignment'
    'New-AzureADMSAdministrativeUnit'                                   = 'New-MgDirectoryAdministrativeUnit'
    'New-AzureADMSAdministrativeUnitMember'                             = 'New-MgDirectoryAdministrativeUnitMember'
    'New-AzureADMSApplication'                                          = 'New-MgApplication'
    'New-AzureADMSApplicationExtensionProperty'                         = 'New-MgApplicationExtensionProperty'
    'New-AzureADMSApplicationFromApplicationTemplate'                   = 'Invoke-MgInstantiateApplicationTemplate'
    'New-AzureADMSApplicationKey'                                       = 'Add-MgApplicationKey'
    'New-AzureADMSApplicationPassword'                                  = 'Add-MgApplicationPassword'
    'New-AzureADMSAttributeSet'                                         = 'New-MgDirectoryAttributeSet'
    'New-AzureADMSConditionalAccessPolicy'                              = 'New-MgIdentityConditionalAccessPolicy'
    'New-AzureADMSCustomSecurityAttributeDefinition'                    = 'New-MgDirectoryCustomSecurityAttributeDefinition'
    'New-AzureADMSFeatureRolloutPolicy'                                 = 'New-MgPolicyFeatureRolloutPolicy'
    'New-AzureADMSGroup'                                                = 'New-MgGroup'
    'New-AzureADMSGroupLifecyclePolicy'                                 = 'New-MgGroupLifecyclePolicy'
    'New-AzureADMSIdentityProvider'                                     = 'New-MgIdentityProvider'
    'New-AzureADMSInvitation'                                           = 'New-MgInvitation'
    'New-AzureADMSNamedLocationPolicy'                                  = 'New-MgIdentityConditionalAccessNamedLocation'
    'New-AzureADMSPasswordSingleSignOnCredential'                       = 'New-MgBetaServicePrincipalPasswordSingleSignOnCredential'
    'New-AzureADMSPermissionGrantConditionSet'                          = 'New-MgPolicyPermissionGrantPolicyInclude'
    'New-AzureADMSPermissionGrantPolicy'                                = 'New-MgPolicyPermissionGrantPolicy'
    'New-AzureADMSRoleAssignment'                                       = 'New-MgRoleManagementDirectoryRoleAssignment'
    'New-AzureADMSRoleDefinition'                                       = 'New-MgRoleManagementDirectoryRoleDefinition'
    'New-AzureADMSServicePrincipal'                                     = 'New-MgServicePrincipal'
    'New-AzureADMSTrustFrameworkPolicy'                                 = 'New-MgBetaTrustFrameworkPolicy'
    'New-AzureADMSUser'                                                 = 'New-MgUser'
    'New-AzureADObjectSetting'                                          = 'New-MgGroupSetting'
    'New-AzureADPolicy'                                                 = 'New-MgPolicyActivityBasedTimeoutPolicy'
    'New-AzureADPrivilegedRoleAssignment'                               = 'Deprecated'
    'New-AzureADServiceAppRoleAssignment'                               = 'New-MgServicePrincipalAppRoleAssignment'
    'New-AzureADServicePrincipal'                                       = 'New-MgServicePrincipal'
    'New-AzureADServicePrincipalKeyCredential'                          = 'Add-MgServicePrincipalKey,Update-MgServicePrincipal'
    'New-AzureADServicePrincipalPasswordCredential'                     = 'Add-MgServicePrincipalPassword'
    'New-AzureADTrustedCertificateAuthority'                            = 'New-MgOrganizationCertificateBasedAuthConfiguration'
    'New-AzureADUser'                                                   = 'New-MgUser'
    'New-AzureADUserAppRoleAssignment'                                  = 'New-MgUserAppRoleAssignment'
    'New-MsolAdministrativeUnit'                                        = 'New-MgDirectoryAdministrativeUnit'
    'New-MsolDomain'                                                    = 'New-MgDomain'
    'New-MsolFederatedDomain'                                           = 'New-MgDomainFederationConfiguration'
    'New-MsolGroup'                                                     = 'New-MgGroup'
    'New-MsolLicenseOptions'                                            = 'Set-MgUserLicense'
    'New-MsolServicePrincipal'                                          = 'New-MgServicePrincipal'
    'New-MsolServicePrincipalAddresses'                                 = 'New-MgServicePrincipal'
    'New-MsolServicePrincipalCredential'                                = 'Add-MgServicePrincipalKey'
    'New-MsolUser'                                                      = 'New-MgUser'
    'New-MsolWellKnownGroup'                                            = 'N.A.'
    'Open-AzureADMSPrivilegedRoleAssignmentRequest'                     = 'Deprecated'
    'Redo-MsolProvisionContact'                                         = 'Invoke-MgRetryContactServiceProvisioning'
    'Redo-MsolProvisionGroup'                                           = 'Invoke-MgRetryGroupServiceProvisioning'
    'Redo-MsolProvisionUser'                                            = 'Invoke-MgRetryUserServiceProvisioning'
    'Remove-AzureADAdministrativeUnit'                                  = 'Remove-MgDirectoryAdministrativeUnit'
    'Remove-AzureADAdministrativeUnitMember'                            = 'Remove-MgDirectoryAdministrativeUnitMemberByRef'
    'Remove-AzureADApplication'                                         = 'Remove-MgApplication'
    'Remove-AzureADApplicationExtensionProperty'                        = 'Remove-MgApplicationExtensionProperty'
    'Remove-AzureADApplicationKeyCredential'                            = 'Remove-MgApplicationKey'
    'Remove-AzureADApplicationOwner'                                    = 'Remove-MgApplicationOwnerByRef'
    'Remove-AzureADApplicationPasswordCredential'                       = 'Remove-MgApplicationPassword'
    'Remove-AzureADApplicationPolicy'                                   = 'Remove-MgApplicationAppManagementPolicyByRef'
    'Remove-AzureADApplicationProxyApplication'                         = 'N.A.'
    'Remove-AzureADApplicationProxyApplicationConnectorGroup'           = 'N.A.'
    'Remove-AzureADApplicationProxyConnectorGroup'                      = 'Remove-MgBetaOnPremisePublishingProfileConnectorGroup'
    'Remove-AzureADContact'                                             = 'Remove-MgContact'
    'Remove-AzureADContactManager'                                      = 'N.A.'
    'Remove-AzureADDeletedApplication'                                  = 'Remove-MgDirectoryDeletedItem'
    'Remove-AzureADDevice'                                              = 'Remove-MgDevice'
    'Remove-AzureADDeviceRegisteredOwner'                               = 'Remove-MgDeviceRegisteredOwnerByRef'
    'Remove-AzureADDeviceRegisteredUser'                                = 'Remove-MgDeviceRegisteredUserByRef'
    'Remove-AzureADDirectoryRoleMember'                                 = 'Remove-MgDirectoryRoleMemberByRef'
    'Remove-AzureADDirectorySetting'                                    = 'Remove-MgBetaDirectorySetting'
    'Remove-AzureADDomain'                                              = 'Remove-MgDomain'
    'Remove-AzureADExternalDomainFederation'                            = 'Remove-MgDirectoryFederationConfiguration'
    'Remove-AzureADGroup'                                               = 'Remove-MgGroup'
    'Remove-AzureADGroupAppRoleAssignment'                              = 'Remove-MgGroupAppRoleAssignment'
    'Remove-AzureADGroupMember'                                         = 'Remove-MgGroupMemberByRef'
    'Remove-AzureADGroupOwner'                                          = 'Remove-MgGroupOwnerByRef'
    'Remove-AzureADMSAdministrativeUnit'                                = 'Remove-MgDirectoryAdministrativeUnit'
    'Remove-AzureADMSAdministrativeUnitMember'                          = 'Remove-MgDirectoryAdministrativeUnitMemberByRef'
    'Remove-AzureADMSApplication'                                       = 'Remove-MgApplication'
    'Remove-AzureADMSApplicationExtensionProperty'                      = 'Remove-MgApplicationExtensionProperty'
    'Remove-AzureADMSApplicationKey'                                    = 'Remove-MgApplicationKey'
    'Remove-AzureADMSApplicationOwner'                                  = 'Remove-MgApplicationOwnerByRef'
    'Remove-AzureADMSApplicationPassword'                               = 'Remove-MgApplicationPassword'
    'Remove-AzureADMSApplicationVerifiedPublisher'                      = 'Clear-MgApplicationVerifiedPublisher'
    'Remove-AzureADMSConditionalAccessPolicy'                           = 'Remove-MgIdentityConditionalAccessPolicy'
    'Remove-AzureADMSDeletedDirectoryObject'                            = 'Remove-MgDirectoryObject'
    'Remove-AzureADMSFeatureRolloutPolicy'                              = 'Remove-MgPolicyFeatureRolloutPolicy'
    'Remove-AzureADMSFeatureRolloutPolicyDirectoryObject'               = 'Remove-MgPolicyFeatureRolloutPolicyApplyToDirectoryObjectByRef'
    'Remove-AzureADMSGroup'                                             = 'Remove-MgGroup'
    'Remove-AzureADMSGroupLifecyclePolicy'                              = 'Remove-MgGroupLifecyclePolicy'
    'Remove-AzureADMSIdentityProvider'                                  = 'Remove-MgIdentityProvider'
    'Remove-AzureADMSLifecyclePolicyGroup'                              = 'Remove-MgGroupFromLifecyclePolicy'
    'Remove-AzureADMSNamedLocationPolicy'                               = 'Remove-MgIdentityConditionalAccessNamedLocation'
    'Remove-AzureADMSPasswordSingleSignOnCredential'                    = 'Remove-MgBetaServicePrincipalPasswordSingleSignOnCredential'
    'Remove-AzureADMSPermissionGrantConditionSet'                       = 'Remove-MgPolicyPermissionGrantPolicyInclude'
    'Remove-AzureADMSPermissionGrantPolicy'                             = 'Remove-MgPolicyPermissionGrantPolicy'
    'Remove-AzureADMSRoleAssignment'                                    = 'Remove-MgRoleManagementDirectoryRoleAssignment'
    'Remove-AzureADMSRoleDefinition'                                    = 'Remove-MgRoleManagementDirectoryRoleDefinition'
    'Remove-AzureADMSScopedRoleMembership'                              = 'Remove-MgUserScopedRoleMemberOf'
    'Remove-AzureADMSServicePrincipalDelegatedPermissionClassification' = 'Remove-MgServicePrincipalDelegatedPermissionClassification'
    'Remove-AzureADMSTrustFrameworkPolicy'                              = 'Remove-MgBetaTrustFrameworkPolicy'
    'Remove-AzureADOAuth2PermissionGrant'                               = 'Remove-MgOauth2PermissionGrant'
    'Remove-AzureADObjectSetting'                                       = 'Remove-MgGroupSetting'
    'Remove-AzureADPolicy'                                              = 'Remove-MgPolicyActivityBasedTimeoutPolicy,Remove-MgPolicyDefaultAppManagementPolicy,Remove-MgPolicyAppManagementPolicy,Remove-MgPolicyAuthenticationFlowPolicy,Remove-MgPolicyAuthenticationMethodPolicy,Remove-MgPolicyClaimMappingPolicy,Remove-MgPolicyFeatureRolloutPolicyApplyToDirectoryObjectByRef,Remove-MgPolicyHomeRealmDiscoveryPolicy,Remove-MgPolicyPermissionGrantPolicy,Remove-MgPolicyTokenIssuancePolicy,Remove-MgPolicyTokenLifetimePolicy'
    'Remove-AzureADScopedRoleMembership'                                = 'Remove-MgDirectoryAdministrativeUnitScopedRoleMember'
    'Remove-AzureADServiceAppRoleAssignment'                            = 'Remove-MgServicePrincipalAppRoleAssignment'
    'Remove-AzureADServicePrincipal'                                    = 'Remove-MgServicePrincipal'
    'Remove-AzureADServicePrincipalKeyCredential'                       = 'Remove-MgServicePrincipalKey'
    'Remove-AzureADServicePrincipalOwner'                               = 'Remove-MgServicePrincipalOwnerByRef'
    'Remove-AzureADServicePrincipalPasswordCredential'                  = 'Remove-MgServicePrincipalPassword'
    'Remove-AzureADServicePrincipalPolicy'                              = 'Remove-MgServicePrincipalClaimMappingPolicyByRef,Remove-MgServicePrincipalHomeRealmDiscoveryPolicyByRef'
    'Remove-AzureADTrustedCertificateAuthority'                         = 'Remove-MgOrganizationCertificateBasedAuthConfiguration'
    'Remove-AzureADUser'                                                = 'Remove-MgUser'
    'Remove-AzureADUserAppRoleAssignment'                               = 'Remove-MgUserAppRoleAssignment'
    'Remove-AzureADUserExtension'                                       = 'Remove-MgUserExtension'
    'Remove-AzureADUserManager'                                         = 'Remove-MgUserManagerByRef'
    'Remove-MsolAdministrativeUnit'                                     = 'Remove-MgDirectoryAdministrativeUnit'
    'Remove-MsolAdministrativeUnitMember'                               = 'Remove-MgDirectoryAdministrativeUnitScopedRoleMember'
    'Remove-MsolApplicationPassword'                                    = 'Remove-MgApplicationPassword'
    'Remove-MsolContact'                                                = 'Remove-MgContact'
    'Remove-MsolDevice'                                                 = 'Remove-MgDevice'
    'Remove-MsolDomain'                                                 = 'Remove-MgDomain'
    'Remove-MsolFederatedDomain'                                        = 'Remove-MgDomainFederationConfiguration'
    'Remove-MsolForeignGroupFromRole'                                   = 'N.A.'
    'Remove-MsolGroup'                                                  = 'Remove-MgGroup'
    'Remove-MsolGroupMember'                                            = 'Remove-MgGroupMemberByRef'
    'Remove-MsolRoleMember'                                             = 'Remove-MgDirectoryRoleMemberByRef'
    'Remove-MsolScopedRoleMember'                                       = 'Remove-MgDirectoryRoleScopedMember'
    'Remove-MsolServicePrincipal'                                       = 'Remove-MgServicePrincipal'
    'Remove-MsolServicePrincipalCredential'                             = 'Remove-MgServicePrincipalKey'
    'Remove-MsolUser'                                                   = 'Remove-MgUser'
    'Reset-AzureADMSLifeCycleGroup'                                     = 'Invoke-MgRenewGroup'
    'Reset-MsolStrongAuthenticationMethodByUpn'                         = 'N.A.'
    'Restore-AzureADDeletedApplication'                                 = 'Restore-MgDirectoryDeletedItem'
    'Restore-AzureADMSDeletedDirectoryObject'                           = 'Restore-MgDirectoryDeletedItem'
    'Restore-MsolUser'                                                  = 'Restore-MgDirectoryDeletedItem'
    'Revoke-AzureADSignedInUserAllRefreshToken'                         = 'Revoke-MgUserSignInSession'
    'Revoke-AzureADUserAllRefreshToken'                                 = 'Revoke-MgUserSignInSession'
    'Select-AzureADGroupIdsContactIsMemberOf'                           = 'Get-MgContactMemberOf'
    'Select-AzureADGroupIdsGroupIsMemberOf'                             = 'Get-MgGroupMemberOf'
    'Select-AzureADGroupIdsServicePrincipalIsMemberOf'                  = 'Get-MgServicePrincipalMemberOf'
    'Select-AzureADGroupIdsUserIsMemberOf'                              = 'Get-MgUserMemberOf'
    'Set-AzureADAdministrativeUnit'                                     = 'Update-MgDirectoryAdministrativeUnit'
    'Set-AzureADApplication'                                            = 'Update-MgApplication'
    'Set-AzureADApplicationLogo'                                        = 'Set-MgApplicationLogo'
    'Set-AzureADApplicationProxyApplication'                            = 'N.A.'
    'Set-AzureADApplicationProxyApplicationConnectorGroup'              = 'Set-MgBetaApplicationConnectorGroupByRef'
    'Set-AzureADApplicationProxyApplicationCustomDomainCertificate'     = 'N.A.'
    'Set-AzureADApplicationProxyApplicationSingleSignOn'                = 'N.A.'
    'Set-AzureADApplicationProxyConnector'                              = 'Update-MgBetaOnPremisePublishingProfileConnector'
    'Set-AzureADApplicationProxyConnectorGroup'                         = 'Update-MgBetaOnPremisePublishingProfileConnectorGroup'
    'Set-AzureADDevice'                                                 = 'Update-MgDevice'
    'Set-AzureADDirectorySetting'                                       = 'Update-MgBetaDirectorySetting'
    'Set-AzureADDomain'                                                 = 'Update-MgDomain'
    'Set-AzureADGroup'                                                  = 'Update-MgGroup'
    'Set-AzureADMSAdministrativeUnit'                                   = 'Update-MgDirectoryAdministrativeUnit'
    'Set-AzureADMSApplication'                                          = 'Update-MgApplication'
    'Set-AzureADMSApplicationLogo'                                      = 'Set-MgApplicationLogo'
    'Set-AzureADMSApplicationVerifiedPublisher'                         = 'Set-MgApplicationVerifiedPublisher'
    'Set-AzureADMSAttributeSet'                                         = 'Update-MgDirectoryAttributeSet'
    'Set-AzureADMSAuthorizationPolicy'                                  = 'Update-MgPolicyAuthorizationPolicy'
    'Set-AzureADMSConditionalAccessPolicy'                              = 'Update-MgIdentityConditionalAccessPolicy'
    'Set-AzureADMSCustomSecurityAttributeDefinition'                    = 'Update-MgDirectoryCustomSecurityAttributeDefinition'
    'Set-AzureADMSCustomSecurityAttributeDefinitionAllowedValue'        = 'Update-MgDirectoryCustomSecurityAttributeDefinitionAllowedValue'
    'Set-AzureADMSFeatureRolloutPolicy'                                 = 'Update-MgPolicyFeatureRolloutPolicy'
    'Set-AzureADMSGroup'                                                = 'Update-MgGroup'
    'Set-AzureADMSGroupLifecyclePolicy'                                 = 'Update-MgGroupLifecyclePolicy'
    'Set-AzureADMSIdentityProvider'                                     = 'Update-MgIdentityProvider'
    'Set-AzureADMSNamedLocationPolicy'                                  = 'Update-MgIdentityConditionalAccessNamedLocation'
    'Set-AzureADMSPasswordSingleSignOnCredential'                       = 'Update-MgBetaServicePrincipalPasswordSingleSignOnCredential'
    'Set-AzureADMSPermissionGrantConditionSet'                          = 'Update-MgPolicyPermissionGrantPolicyExclude,Update-MgPolicyPermissionGrantPolicyInclude'
    'Set-AzureADMSPermissionGrantPolicy'                                = 'Update-MgPolicyPermissionGrantPolicy'
    'Set-AzureADMSPrivilegedRoleAssignmentRequest'                      = 'Deprecated'
    'Set-AzureADMSPrivilegedRoleSetting'                                = 'Update-MgBetaPrivilegedAccessRoleSetting'
    'Set-AzureADMSRoleDefinition'                                       = 'Update-MgRoleManagementDirectoryRoleDefinition'
    'Set-AzureADMSServicePrincipal'                                     = 'Update-MgServicePrincipal'
    'Set-AzureADMSTrustFrameworkPolicy'                                 = 'Update-MgBetaTrustFrameworkPolicy'
    'Set-AzureADMSUser'                                                 = 'Update-MgUser'
    'Set-AzureADObjectSetting'                                          = 'Update-MgGroupSetting'
    'Set-AzureADPolicy'                                                 = 'Update-MgPolicyActivityBasedTimeoutPolicy,Update-MgPolicyDefaultAppManagementPolicy,Update-MgPolicyAppManagementPolicy,Update-MgPolicyAuthenticationFlowPolicy,Update-MgPolicyAuthenticationMethodPolicy,Update-MgPolicyClaimMappingPolicy,Update-MgPolicyFeatureRolloutPolicy,Update-MgPolicyHomeRealmDiscoveryPolicy,Update-MgPolicyPermissionGrantPolicy,Update-MgPolicyTokenIssuancePolicy,Update-MgPolicyTokenLifetimePolicy'
    'Set-AzureADServicePrincipal'                                       = 'Update-MgServicePrincipal'
    'Set-AzureADTenantDetail'                                           = 'Update-MgOrganization'
    'Set-AzureADTrustedCertificateAuthority'                            = 'N.A.'
    'Set-AzureADUser'                                                   = 'Update-MgUser'
    'Set-AzureADUserExtension'                                          = 'Update-MgUser'
    'Set-AzureADUserLicense'                                            = 'Set-MgUserLicense'
    'Set-AzureADUserManager'                                            = 'Set-MgUserManagerByRef'
    'Set-AzureADUserPassword'                                           = 'Update-MgUser'
    'Set-AzureADUserThumbnailPhoto'                                     = 'Set-MgUserPhotoContent'
    'Set-MsolADFSContext'                                               = 'N.A.'
    'Set-MsolAdministrativeUnit'                                        = 'Update-MgDirectoryAdministrativeUnit'
    'Set-MsolCompanyAllowedDataLocation'                                = 'N.A.'
    'Set-MsolCompanyContactInformation'                                 = 'Update-MgOrganization'
    'Set-MsolCompanyMultiNationalEnabled'                               = 'N.A.'
    'Set-MsolCompanySecurityComplianceContactInformation'               = 'Update-MgOrganization'
    'Set-MsolCompanySettings'                                           = 'Update-MgOrganization,Update-MgPolicyAuthorizationPolicy'
    'Set-MsolDeviceRegistrationServicePolicy'                           = 'N.A.'
    'Set-MsolDirSyncConfiguration'                                      = 'Update-MgDirectoryOnPremiseSynchronization'
    'Set-MsolDirSyncEnabled'                                            = 'Update-MgOrganization'
    'Set-MsolDirSyncFeature'                                            = 'Update-MgDirectoryOnPremiseSynchronization'
    'Set-MsolDomain'                                                    = 'Update-MgDomain'
    'Set-MsolDomainAuthentication'                                      = 'New-MgDomainFederationConfiguration'
    'Set-MsolDomainFederationSettings'                                  = 'New-MgDomainFederationConfiguration'
    'Set-MsolGroup'                                                     = 'Update-MgGroup'
    'Set-MsolPartnerInformation'                                        = 'N.A.'
    'Set-MsolPasswordPolicy'                                            = 'Update-MgDomain'
    'Set-MsolServicePrincipal'                                          = 'Update-MgServicePrincipal'
    'Set-MsolUser'                                                      = 'Update-MgUser'
    'Set-MsolUserLicense'                                               = 'Set-MgUserLicense'
    'Set-MsolUserPassword'                                              = 'Reset-MgUserAuthenticationMethodPassword'
    'Set-MsolUserPrincipalName'                                         = 'Update-MgUser'
    'Update-AzureADSignedInUserPassword'                                = 'Update-MgUserPassword'
    'Update-MsolFederatedDomain'                                        = 'Update-MgDomainFederationConfiguration'
}

#Check if specified file is correct and store path of $Filname in $ScriptFiles
if ($Filename) {
    if (Test-Path -Path $Filename) {
        Write-Host ("The specified file {0} is valid, scanning now..." -f $Filename) -ForegroundColor Green
        $ScriptFiles = (Get-ChildItem -Path $Filename).FullName
    }
    else {
        Write-Warning ("The specified file {0} is invalid, exiting..." -f $Filename)
        return
    }
}

#Check if specified folder is correct and store the filenames in $ScriptFiles
if ($Folder) {
    if ((Get-Item -Path $Folder).PSisContainer -eq $true) {
        Write-Host ("The specified folder {0} is valid, checking for .ps1 files..." -f $Folder) -ForegroundColor Green
        $ScriptFiles = Get-ChildItem -Path $Folder -Filter *.ps1 -Recurse
        if ($ScriptFiles.count -gt 0) {
            Write-Host ("The specified folder contains {0} .ps1 file(s), scanning..." -f $ScriptFiles.count) -ForegroundColor Green
        }
        else {
            Write-Warning ("The specified folder {0} is valid, but no .ps1 files were found. Exiting..." -f $Folder)
            return
        }
    }
    else {
        Write-Warning ("The specified folder {0} is invalid or is a file instead of a folder, exiting..." -f $Folder)
        return
    }
}

#$Verbs variable with valid PowerShell verbs to search for
#https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.4 / Get-Verb
$Verbs = (Get-Verb).Verb

#loop through each line in the script and get all the cmdlets being used
#that are based on the approved verbs above, add to $Total when matched on deprecated CmdLets
$Total = foreach ($ScriptFile in $ScriptFiles) {
    $Scriptcontents = Get-Content -Path $ScriptFile | Select-String . | Select-Object Line, Linenumber
    foreach ($Line in $ScriptContents) {
        if (-not ($Line.Line.StartsWith('#'))) {
            foreach ($Word in $Line.line.Split(' ')) {
                foreach ($Verb in $Verbs) {
                    if ($Word.ToLower().StartsWith($Verb.ToLower() + '-') ) {
                        $CmdLet = $Word -replace '[\{\}\(\)\\]', ''
                        if ($Commands[$CmdLet]) {
                            [PSCustomObject]@{
                                Filename            = $ScriptFile
                                'Deprecated CmdLet' = $CmdLet 
                                'New CmdLet'        = $Commands[$CmdLet]
                                Line                = $Line.linenumber 
                            }
                        }
                    }
                }
            }
        }
    }
}

#Output results to screen if found
if ($Total.Length -gt 0) {
    Write-Warning ("Old Cmdlets found!")
    $Total | Format-Table -AutoSize
}
else {
    Write-Host ("No old CmdLets found") -ForegroundColor Green
}

#Output results to specified .csv of .xlsx, install ImportExcel Module if needed
if ($OutFile) {
    if ($Outfile.EndsWith('.csv')) {
        try {
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $total | Sort-Object Name, Property | Export-Csv -Path $Outfile -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }
    
    if ($Outfile.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because xlsx is corrupted if not
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $Outfile -Force:$true -Confirm:$false | Out-Null
            
            #Install ImportExcel module if needed
            Write-Host ("Checking if ImportExcel PowerShell module is installed...") -ForegroundColor Green
            if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                Install-Module ImportExcel -Scope CurrentUser -Force:$true
                Import-Module ImportExcel
            }
            #Export results to path
            $total | Sort-Object name, Property | Export-Excel -BoldTopRow -FreezeTopRow -AutoFilter -AutoSize -Path $Outfile
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }

    if (-not $OutFile.EndsWith('.csv') -and -not $OutFile.EndsWith('.xlsx')) {
        Write-Warning ("Specified file {0} does not end with either .csv or .xlsx, not exporting results because of that." -f $OutFile)
    }
}