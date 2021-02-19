<#

.SYNOPSIS
    Provide the SPN secrets and store them in keyvault 

.DESCRIPTION
    The script saves the SPN credentials in the key vault.


.EXAMPLE
    ./Install-Deployer.ps1 

.LI

.NOTES
    v0.1 - Initial version

#>
<#
Copyright (c) Microsoft Corporation.
Licensed under the MIT license.
#>
function New-Deployer {
    [OutputType([Bool])]

    param(
        #Parameter file
        [Parameter(Mandatory = $true)][string]$Parameterfile
         )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Deploying the deployer"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath


    [IO.FileInfo] $fInfo = $Parameterfile
    $environmentname = ($fInfo.Name -split "-")[0]


    # Subscription
    $sub = $iniContent[$environmentname]["subscription"] 
    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$environmentname]["subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the subscription"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        $iniContent | Out-IniFile -Force $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\bootstrap\sap_deployer"

    Write-Host -ForegroundColor green "Initializing Terraform"

    if (Test-Path ".terraform" -PathType Container) {
        $ans = Read-Host -Prompt ".terraform already exists, do you want to continue Y/N?"

        if ("Y" -ne $ans) {
            exit 0
        }
        else {
            $Command = " init -upgrade=true -reconfigure " + $terraform_module_directory
        }

    }
    else {
        $Command = " init -upgrade=true " + $terraform_module_directory
    }

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running plan"
    $Command = " plan -var-file " + $Parameterfile + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running apply"
    $Command = " apply -var-file " + $Parameterfile + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    New-Item -Path . -Name "backend.tf" -ItemType "file" -Value "terraform {`n  backend ""local"" {}`n}" -Force

    $Command = " output deployer_kv_user_name"

    $Cmd = "terraform $Command"
    $kvName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    $iniContent[$environmentname]["Vault"] = $kvName
    $iniContent | Out-IniFile -Force $filePath

}
