<#
.SYNOPSIS
    Scans for inactive users and triggers a Power Automate flow for governance.
    
.DESCRIPTION
    This script imports user usage data (simulated via CSV for this demo),
    identifies users inactive for more than 90 days, and sends a JSON payload
    to a Power Automate HTTP endpoint.

.NOTES
    Author: [Leandro Farias]
    Date: 2025-10-27
    Context: Collaboration Tools Management Demo
#>

# Configuration
$FlowUrl = "https://prod-00.westus.logic.azure.com:443/workflows/..." # Placeholder
$DaysInactiveThreshold = 90
$ReportPath = ".\dummy-data\UserActivityReport.csv"

# Simulate Data Import (In production, this would use Get-MgUser or Get-MsolUser)
$Users = Import-Csv $ReportPath

# Filter Logic
$InactiveUsers = $Users | Where-Object { 
    $LastLogin = [datetime]$_.LastActivityDate
    $DaysSinceLogin = (Get-Date) - $LastLogin
    $DaysSinceLogin.Days -gt $DaysInactiveThreshold 
}

# Processing
foreach ($User in $InactiveUsers) {
    Write-Host "Processing User: $($User.UserEmail) - Inactive for $($User.DaysInactive) days" -ForegroundColor Yellow
    
    # Construct Payload for Power Automate
    $Body = @{
        UserEmail = $User.UserEmail
        ManagerEmail = $User.ManagerEmail
        DaysInactive = $User.DaysInactive
        LicenseType = $User.LicenseType
    }
    
    # Send to Automation Flow
    try {
        Invoke-RestMethod -Uri $FlowUrl -Method Post -Body ($Body | ConvertTo-Json) -ContentType "application/json"
        Write-Host " -> Trigger sent successfully." -ForegroundColor Green
    }
    catch {
        Write-Error " -> Failed to trigger flow for $($User.UserEmail)"
    }
}