## Variables

$subId = 'xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx'
$location = 'UKSouth'
$rgName = 'rg-mhsm-uks-d-01'
$vaultName = 'mhsm-uks-d-01'
$vaultAdminUPN = 'user.name@contoso.onmicrosoft.com'


## Login and Select Subscription

Login-AzAccount
Select-AzSubscription -subscription $subId

## Create a resource group

$rg = New-AzResourceGroup -Name $rgName -Location $location

## Get your User Details
$aduser = Get-AzADUser -UserPrincipalName $vaultAdminUPN


$kvmhsm = New-AzKeyVaultManagedHsm -Name $vaultName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Administrator $aduser.Id

## Activate you Keyvault - OPENSSL I required

openssl req -newkey rsa:2048 -nodes -keyout cert_0.key -x509 -days 365 -out cert_0.cer
openssl req -newkey rsa:2048 -nodes -keyout cert_1.key -x509 -days 365 -out cert_1.cer
openssl req -newkey rsa:2048 -nodes -keyout cert_2.key -x509 -days 365 -out cert_2.cer

Export-AzKeyVaultSecurityDomain -Name $kvmhsm.Name -Certificates "cert_0.cer", "cert_1.cer", "cert_2.cer" -OutputPath "MHSMsd.ps.json" -Quorum 2


## Add Role Assignments required for Data Plane Operations

az keyvault role assignment create  --hsm-name $kvmhsm.name --assignee $aduser.id  --scope / --role "Managed HSM Crypto User"
az keyvault role assignment create  --hsm-name $kvmhsm.name --assignee $aduser.id  --scope / --role "Managed HSM Crypto Officer"

Get-AzKeyVaultRoleAssignment -HsmName $kvmhsm.name

## Create a key that can be consumed by your applications

Add-AzKeyVaultKey -Name myRsaKey -HsmName $kvmhsm.Name -KeyOps wrapKey.unwrapKe -KeyType RSA-HSM -Size 2048

## Clean Up your Resources

Remove-AzResourceGroup $rg.ResourceGroupName -Force









