# Install CM Module If not already
If ((Get-Module -ListAvailable -Name CredentialManager).Count -lt 0) {
    Install-Module CredentialManager -force -Scope CurrentUser
}

# Setup VM in RDP file
$RDP_PATH_DEFAULT = ".\W10-AVANADE.rdp"
$RDP_PATH = If([string]::IsNullOrWhiteSpace($RDP_PATH_DEFAULT)) { Read-Host "Insert the path of .rdp file to utilize" } Else { $RDP_PATH_DEFAULT }

$VM_NAME_DEFAULT = "W10-AVANADE"
$VM_NAME = If([string]::IsNullOrWhiteSpace($VM_NAME_DEFAULT)) { Read-Host "Insert the vm name" } Else { $VM_NAME_DEFAULT }
$VM_IP = (Get-VM $VM_NAME | Get-VMNetworkAdapter)[0].IPAddresses[0]
((Get-Content -Path $RDP_PATH) -Replace 'full address:s:\d.+',"full address:s:$($VM_IP)") | Set-Content -Path $RDP_PATH

$USERNAME_DEFAULT = "Daniele"
$USERNAME = If([string]::IsNullOrWhiteSpace($USERNAME_DEFAULT)) { Read-Host "Insert the username" } Else { $USERNAME_DEFAULT }

$IS_PASSWORD_NEEDED_DEFAULT = "Y"
$IS_PASSWORD_NEEDED = If([string]::IsNullOrWhiteSpace($IS_PASSWORD_NEEDED_DEFAULT)) { Read-Host "Is password needed? (Y / N)" } Else { $IS_PASSWORD_NEEDED_DEFAULT }
$PASSWORD_DEFAULT = "Mawile.123"
$PASSWORD = If([string]::IsNullOrWhiteSpace($PASSWORD_DEFAULT) -and $IS_PASSWORD_NEEDED.Equals("Y")) { Read-Host "Insert the password" } Else { $PASSWORD_DEFAULT }

# Set Windows Credentials (and remove old If wrong)
If((Get-StoredCredential -Target $VM_IP).Count -eq 0) {
    $CRED_TO_REMOVE_TARGET = ((Get-StoredCredential -AsCredentialObject | Where-Object {$_.UserName -eq $USERNAME}).TargetName -match 'LegacyGeneric:target=\d.+' -split '=')[1]

    If(![string]::IsNullOrWhiteSpace($CRED_TO_REMOVE_TARGET)) {
        Remove-StoredCredential -Target $CRED_TO_REMOVE_TARGET
    }

    New-StoredCredential -Target $VM_IP -UserName $USERNAME -Password $PASSWORD -Persist LocalMachine
}

# Execute RDP file
Invoke-Item $RDP_PATH

