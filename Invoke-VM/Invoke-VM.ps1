# Install CM Module If not already
If ((Get-Module -ListAvailable -Name CredentialManager).Count -lt 0) 
{
    Install-Module CredentialManager -force -Scope CurrentUser
}

#Install Yaml module for settings
If ((Get-Module -ListAvailable -Name powershell-yaml).Count -lt 0) 
{
    Install-Module powershell-yaml -force -Scope CurrentUser
}

# Setup VM in RDP file
$DEFAULTS = Get-Content -Path ".\invoke-vm.yaml" | ConvertFrom-Yaml 
$RDP_PATH_DEFAULT = $DEFAULTS.Rdp.Path
$RDP_PATH = If([string]::IsNullOrWhiteSpace($RDP_PATH_DEFAULT)) { Read-Host "Insert the path of .rdp file to utilize" } Else { $RDP_PATH_DEFAULT }

$VM_NAME_DEFAULT = $DEFAULTS.VM.Name
$VM_NAME = If([string]::IsNullOrWhiteSpace($VM_NAME_DEFAULT)) { Read-Host "Insert the vm name" } Else { $VM_NAME_DEFAULT }
$VM_IP = (Get-VM $VM_NAME | Get-VMNetworkAdapter)[0].IPAddresses[0]

If([string]::IsNullOrWhiteSpace($VM_IP)) 
{ 
    $VM_START = Read-Host "VM is down. Do you want to start it? (Y / N)" 
    Write-Host $VM_START
    switch($VM_START) 
    {
        "Y"
        {
            Start-VM $VM_NAME
            Write-Host "Vm is starting..."
            do 
            {
                $VM = Get-VM $VM_NAME
            } while ($VM.Heartbeat -ne 'OkApplicationsUnknown')

            $VM_IP = (Get-VM $VM_NAME | Get-VMNetworkAdapter)[0].IPAddresses[0]
        }

        "N" { return Read-Host "Cya next time! (Click any key to close)" }

        default { return Read-Host "Invalid input. Click any key to close" }
    } 
}

((Get-Content -Path $RDP_PATH) -Replace '^full address:s:.*$',"full address:s:$($VM_IP)") | Set-Content -Path $RDP_PATH

$USERNAME_DEFAULT = $DEFAULTS.VM.Username
$USERNAME = If([string]::IsNullOrWhiteSpace($USERNAME_DEFAULT)) { Read-Host "Insert the username" } Else { $USERNAME_DEFAULT }

$IS_PASSWORD_NEEDED_DEFAULT = $DEFAULTS.VM.IsPasswordNeeded
$IS_PASSWORD_NEEDED = If([string]::IsNullOrWhiteSpace($IS_PASSWORD_NEEDED_DEFAULT)) { Read-Host "Is password needed? (Y / N)" } Else { $IS_PASSWORD_NEEDED_DEFAULT }
$PASSWORD_DEFAULT = $DEFAULTS.VM.Password
$PASSWORD = If([string]::IsNullOrWhiteSpace($PASSWORD_DEFAULT) -and $IS_PASSWORD_NEEDED.Equals("Y")) { Read-Host "Insert the password" } Else { $PASSWORD_DEFAULT }

# Set Windows Credentials (and remove old If wrong)
If((Get-StoredCredential -Target $VM_IP).Count -eq 0) 
{
    $CRED_TO_REMOVE_TARGET = ((Get-StoredCredential -AsCredentialObject | Where-Object {$_.UserName -eq $USERNAME}).TargetName -match 'LegacyGeneric:target=\d.+' -split '=')[1]

    If(![string]::IsNullOrWhiteSpace($CRED_TO_REMOVE_TARGET)) 
    {
        Remove-StoredCredential -Target $CRED_TO_REMOVE_TARGET
    }

    New-StoredCredential -Target $VM_IP -UserName $USERNAME -Password $PASSWORD -Persist LocalMachine
}

# Execute RDP file
Invoke-Item $RDP_PATH

