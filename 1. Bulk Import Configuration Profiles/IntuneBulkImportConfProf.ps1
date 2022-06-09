# https://github.com/CloudSecuritea/O365ExportImport/blob/main/ExportAndImport/Intune/export-intune.ps1

Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Microsoft.Graph.Intune
Install-Module AzureAD

Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Intune
Import-Module AzureAD

####################
# Connect to Graph #
####################

Connect-MSGraph

#Configuration policies
$ConfigurationPolicies = (Invoke-MSGraphRequest -Url 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations' -HttpMethod GET).Value
##################
# Export to CSV #
##################

#Configuration policies
try{
  foreach($policy in $ConfigurationPolicies){
	$NewLine = "{0},{1}" -f $policy.displayName,$policy.id
	$NewLine | add-content -path 'PATH\TO\EXPORT\profiles.csv'
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
    #Write-Host $policy.displayName,$policy.id
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

####################
# Connect to AzureAD #
####################
Connect-AzureAD -Confirm

#Groups
# https://stackoverflow.com/questions/58870231/export-all-azure-ad-groups-and-their-owner-to-a-csv-file
try{
	$array = @()
	$Properties=@{}
	$Properties.add("GroupDisplayName","1")
	$Properties.add("GroupId","2")
	# https://stackoverflow.com/questions/9813228/add-rows-to-csv-file-in-powershell
	$groups = Get-AzureADGroup -All $true
	Foreach($group in $groups){
		$Properties.GroupDisplayName=$group.DisplayName
		$Properties.GroupId=$group.ObjectId
        write-host "Exported group: $($group.DisplayName)" -ForegroundColor green
		$obj=New-Object PSObject -Property $Properties
        $array +=$obj 
	}
	$array | export-csv -Path 'PATH\TO\EXPORT\groups.csv' -NoTypeInformation -Encoding UTF8
}catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

##################
# Now we have all the configuration policies in a single CSV file with their names and ids
# and all the groups in a CSV with names and ids
##################

##################
# Create the Excel as you want
##################

##################
# Now that the Excel is ready lets proceed to assigning the profiles to the groups in Intune
##################

$path = "PATH\TO\LOAD\Profiles-Groups.csv"
$csv = Import-Csv -path $path

foreach($line in $csv)
{ 
    $properties = $line | Get-Member -MemberType Properties
    write-host "Top Level: $properties" -ForegroundColor red
    for($i=0; $i -lt $properties.Count-1;$i++)
    {
        $policyid = $properties[$properties.Count-1]
        $policyidvalue = $line | Select -ExpandProperty $policyid.Name
        # $policyuri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations('$policyid')/assign"
        $policyuri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyidvalue/assign"
        write-host "$policyuri" -ForegroundColor white
        $column = $properties[$i]
        write-host "$column" -ForegroundColor yellow
        $AzureADGroupId = $line | Select -ExpandProperty $column.Name
        write-host "AzureADGroupId: $AzureADGroupId" -ForegroundColor green
        $JSON = "{'assignments':[{'id':'','target':{'@odata.type':'#microsoft.graph.groupAssignmentTarget','groupId':'$($AzureADGroupId)'}}]}"
        # Invoke-RestMethod -Uri $policyuri -Headers $AuthHeaders -Method Post -Body $JSON -ErrorAction Stop -ContentType 'application/json'
        Invoke-MSGraphRequest -HttpMethod POST -Url "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyidvalue/assign" -Content $JSON
    }
} 
