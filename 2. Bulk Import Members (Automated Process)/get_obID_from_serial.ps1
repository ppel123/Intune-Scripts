#Connect To Graph
Connect-MSGraph

#Connect To AzureAD
Connect-AzureAD

# txt contains Azure AD Device ID
$deviceSerials = Get-Content "deviceSerials.txt"

foreach($dev in $deviceSerials){

    $Device = Get-IntuneManagedDevice -Filter "SerialNumber eq '$dev'" | Select *
    
    #Get IntuneDeviceID And AzureID
    $DeviceID = $Device.idv
    $AzureID = $Device.azureADDeviceId

    #Get ObjectID
    Get-AzureADDevice -Filter "deviceId eq guid'$AzureID'" | select objectID | Export-Csv "ObjectIDs.csv" -Force -Encoding UTF8 -NoTypeInformation -Append
}

# prepopulate group import template
#Delete line 3 containing an example object id
$objectIDs = Get-Content "ObjectIDs.csv" | select -Skip 1
$objectIDs = $objectIDs.Replace("`"","")
$importTemplate = Get-Content "GroupImportMembersTemplate.csv" | select -First 2 
$importTemplate | Out-File -FilePath 'GroupImportMembersTemplate.txt' -Encoding utf8
$objectIDs | Out-File -FilePath 'GroupImportMembersTemplate.txt' -Append -Force -Encoding utf8
$x = Get-Content "GroupImportMembersTemplate.txt" 
$x | Out-File -Append FinalGroupImportMembersTemplate.csv -Encoding UTF8

if (Test-Path 'ObjectIDs.csv') {
  Remove-Item -Verbose -Force 'ObjectIDs.csv'
}

if (Test-Path 'GroupImportMembersTemplate.txt') {
  Remove-Item -Verbose -Force 'GroupImportMembersTemplate.txt'
}

