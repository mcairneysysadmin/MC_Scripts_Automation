# MC_Scripts_Automation
my general scripts for day to day tasks

## Unattended-Export-SPO-Permissions
To run this script there are several steps required first. 
1. Create a useable key for your app registration
2. Create your app registration and assign it permissions to the graph and sharepoint
3. Upload your key to the app registration

When running the script you will require PowerShell v7.x

Execute the script like the below example from PowerShell 
PS C:\Scripts> .\Unattended-Export-SPO-Permissions.ps1 `
>> -TenantId "0000-0000-0000-0000" `
>> -AppId "0000-0000-0000-0000" `
>>     -CertPath "C:\Certs\PnPAppCert.pfx" `
>>     -CertPasswordPlain "YourPASSWORD" `
>>     -TenantName "TenantName" `
>>     -OutFolder "C:\SPExport" `
>>     -IncludeListPermissions
