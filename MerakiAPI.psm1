
$merakiAPI = "https://dashboard.meraki.com/api/v0"       

$headers = @{
    "X-Cisco-Meraki-API-Key" = "";
    "Content-Type" = "application/json";
}


<#
.SYNOPSIS
This is the base GET call that all GET cmdlets call

.PARAMETER uriStem
This is the url that is listed for the HTTP request on the Meraki API docs

.PARAMETER displayURI
(OPTIONAL) Display the URI that is called, this is only output to the screen and is useful when troubleshooting.  This is a switch parameter which defaults to false.

.EXAMPLE
Get-MerakiAPICall -uriStem "/networks"
This will return all of the Meraki Networks defined for your organization

.EXAMPLE
Get-MerakiAPICall -uriStem "/networks/N_1234"
This will return the network for networkId N_1234 in your organization.  You can obtain the networkId via /networks.  This never changes unless you delete and recreate the network.

#>
function Get-MerakiAPICall {
    Param(
        [parameter(Mandatory=$true)]
        [string]
        $uriStem,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI

    )   

    
    $uri =  "$($merakiAPI)$($uriStem)"       
        
    #if ($displayURI) {
        Write-Host "GET - $($uri)" 
    #}
                          
    $response = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers
  
    if (DoesPropertyExist -MyObject $response -MyPropertyName StatusCode) {
        $ret = $response.Content | ConvertFrom-Json
        $ret
    }
    
}

<#
.SYNOPSIS
Gets all of the organizations your account has access to.  Optionally you can specify the organizationId which will return just that Organization.

.PARAMETER organizationiId
(OPTIONAL) A specific organizationId

.PARAMETER apiKey
(REQUIRED) This is the key generated via the Meraki dashboard for your profile once you've enabled dashboard API access.  This key can be regenerated if ever compromised.  The apikey will be used by all cmdlets in this module so you will only be able to work with one organization at a time unless you specify the APIKEY on any of the cmdlets.

.PARAMETER displayURI
(OPTIONAL) Display the URI that is called, this is only output to the screen and is useful when troubleshooting.  This is a switch parameter which defaults to false.

.EXAMPLE
Get-MerakiOrganizations -apikey YOURAPIKEY
This will return all of the organizations you are associated with in the Meraki dashboard

.EXAMPLE
Get-MerakiOrganizations -organizationId SOMEORGID -apikey YOURAPIKEY
This will return a specific organization if you are associated with it in the Meraki dashboard.  The apikey will be used by all cmdlets in this module so you will only be able to work with one organization at a time unless you specify the APIKEY on any of the cmdlets.

.EXAMPLE
Get-MerakiOrganizations -organizationId SOMEORGID -apikey YOURAPIKEY -displayURI
This will return a specific organization if you are associated with it in the Meraki dashboard.  The apikey will be used by all cmdlets in this module so you will only be able to work with one organization at a time unless you specify the APIKEY on any of the cmdlets.  The displayURI switch will output the URI that was built and requested from Meraki's API.

#>
function Get-MerakiOrganizations {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [int]
        $organizationId,

        [parameter(Mandatory=$true)]
        [string]
        $apikey
    )


    process {
        $ret = $null

        $headers.'X-Cisco-Meraki-API-Key' = $apikey

        if ($organizationId) {
            $req = Get-MerakiAPICall -uriStem "/organizations/$($organizationId)" 
            $ret = [PSCustomObject]@{
                "organizationId" = $req.id
                "name" = $req.name        
            }
        } else {
            $req = Get-MerakiAPICall -uriStem "/organizations" 
            
            $items = {$items}.Invoke()
            foreach($item in $req) {
            
                $items.Add([PSCustomObject]@{
                    "organizationId" = $item.id
                    "name" = $item.name        
                })
                
                
                            
            }
            
            $ret = $items
        }

        $ret
    }
     
}

<#
.SYNOPSIS
Get all the networks for the organization specified.  This does support the pipeline

.PARAMETER organizationId
(REQUIRED)  Get all networks for a specific organization id

.PARAMETER Id
(OPTIONAL)  Get a single network for a specific organization id

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Get-MerakiNetworks -organizationId 12345 -apikey ASDFSDFSDFSDFSDFSDF
Returns all the networks for the organization with an id of 12345.

.EXAMPLE
Get-MerakiNetworks -organizationId 12345 -Id N_12345 -apikey ASDFSDFSDFSDFSDFSDF.
Returns the network from an organization Id of 12345 and a network id of N_12345.

.EXAMPLE
Get-MerakiNetworks -organizationId 12345 -Id N_12345 -apikey ASDFSDFSDFSDFSDFSDF -displayURI.
Returns the network from an organization Id of 12345 and a network id of N_12345.  The displayURI switch will output the URI that was built and requested from Meraki's API.


.EXAMPLE
Get-MerakiOrganizations -organizationId 12345 -apiKey ASDFASDFASDF | Get-MerakiNetworks
Returns all the networks from an organization id of 12345.

.EXAMPLE

#>
function Get-MerakiNetworks {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [int]
        $organizationId,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]
        $Id,

        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI

    )


    Begin {
        $networks = {}

        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }

        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }
    }

    Process {
        
        if ($networkId) {
            $networks = Get-MerakiAPICall "/networks/$($Id)" 
        } else {
            $networks = Get-MerakiAPICall "/organizations/$($organizationId)/networks" 
        }
    
        $networks
    }

    
}

<#
.SYNOPSIS
Helper function that will prompt for the API Key if it sees an empty string in the header
#>
function Get-MerakiAPIKey {
    
    $apiKey = Read-Host -Prompt "Please enter the Meraki API Key"
    $headers.'X-Cisco-Meraki-API-Key' = $apiKey

}

<#
.SYNOPSIS
Get all the devices for the network specified by the Id

.PARAMETER Id
(REQUIRED)  Get a single network for a specific organization id

.PARAMETER serial
(OPTIONAL)  Get a single device for a specific network id

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key


.EXAMPLE
Get-MerakiDevices -id N_1234
Returns all of the devices from network N_1234.  This assumes you've already used another command that specified the apikey.

.EXAMPLE
Get-MerakiDevices -id N_1234 -serial ABCDEFGH
Returns the device with serial number ABCDEFGH from network N_1234

.EXAMPLE
Get-MerakiDevices -id N_1234 -serial ABCDEFGH -apikey ASDFASDFASDFASDF -displayURI
Returns the device with serial number ABCDEFGH from network N_1234

.EXAMPLE
Get-MerakiOrganizations -organizationId 12345 -apiKey ASDFASDFASDF | Get-MerakiNetworks | Get-MerakiDevices
Returns all of the devices for all of the networks from the specified organization.

.EXAMPLE
Get-MerakiOrganizations -organizationId 12345 -apiKey ASDFASDFASDF | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices -serial ABCDEFGH
Returns the device with serial number ABCDEFGH from network N_1234 specifing the organization and network via pipeline.

.EXAMPLE
Get-MerakiOrganizations -organizationId 12345 -apiKey ASDFASDFASDF | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices -serial ABCDEFGH -displayUri
Returns the device with serial number ABCDEFGH from network N_1234 specifing the organization and network via pipeline.  The displayURI switch will output the URI that was built and requested from Meraki's API.  In this case there will be three API calls but only the API call to Get-MerakiDevices will be displayed.

#>
function Get-MerakiDevices {
    [CmdletBinding()]
    Param(       

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]   
        [string]
        $Id,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]   
        [string]
        $serial,

        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI

    )  

    begin {
        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }

        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }

    }

    process {

        if ($Serial) {
            $req = Get-MerakiAPICall -uriStem "/networks/$($id)/devices/$($serial)" 
            $req
        } else {
            $req = Get-MerakiAPICall -uriStem "/networks/$($id)/devices" 
            $req
        }

    }

}

<#
.SYNOPSIS
Get all the clients for the device specified by the serial

.PARAMETER serial
(REQUIRED)  Get all the clients connected to the device.

.PARAMETER timespan
(OPTIONAL)  Time in seconds to view clients that have connected to the device.  Defaults to 864000

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key


.EXAMPLE
Get-MerakiClients -Id N_1234 -serial ABCD-1234-EFGH
Returns all clients connected to device ABCD-1234-EFGH on the network with an id of N_1234.

.EXAMPLE
Get-MerakiClients -Id N_1234 -serial ABCD-1234-EFGH -apikey YOURAPIKEY
Returns all clients connected to device ABCD-1234-EFGH on the network with an id of N_1234.  Specifying the APIKEY allows you to call this method without first calling Get-MerakiOrganizations.

.EXAMPLE
Get-MerakiClients -Id N_1234 -serial ABCD-1234-EFGH -apikey YOURAPIKEY -displayURI
Returns all clients connected to device ABCD-1234-EFGH on the network with an id of N_1234.  Specifying the APIKEY allows you to call this method without first calling Get-MerakiOrganizations.  The displayURI switch will output the URI that was built and requested from Meraki's API.

.EXAMPLE
Get-MerakiOrganizations -organizationId 1234 -apikey YOURAPIKEY | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices -serial ABCD-1234-EFGH | Get-MerakiClients
Returns all clients connected to device ABCD-1234-EFGH on the network with an id of N_1234 for organization with an id 1234.

.EXAMPLE
Get-MerakiOrganizations -organizationId 1234 -apikey YOURAPIKEY | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices | Get-MerakiClients
Returns all of the clients connected to all devices for network N_1234.  This will make a lot of calls to the API.  As of right now you're limited to approximately 300 calls per minute.  So if you have more than a couple hundred Meraki devices you will error out.

#>
function Get-MerakiClients {
    [CmdletBinding()]
    Param(       

        [parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $serial,

        [parameter(Mandatory=$false)]        
        [int]
        $timespan = 86400,

        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI

    )  

    begin {

        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }
        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }
    }
 
    process {
        $clients = Get-MerakiAPICall -uriStem "/devices/$($serial)/clients?timespan=$($timespan)"   
        
        $clients
    }
}

<#
.SYNOPSIS
Get all the clients for the device specified by the serial

.PARAMETER serial
(REQUIRED)  Get all the ports for this switch.

.PARAMETER number
(OPTIONAL)  Get the specific port for this switch

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Get-MerakiSwitchPorts -serial ABCD-1234-EFGH
Returns all of the switch ports for the device with a serial number of ABCD-1234-EFGH.

.EXAMPLE
Get-MerakiSwitchPorts -serial ABCD-1234-EFGH -number 1
Returns port #1 from the device with a serial number of ABCD-1234-EFGH.

.EXAMPLE
Get-MerakiOrganizations -organizationId 1234 -apikey YOURAPIKEY | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices -serial ABCD-1234-EFGH | Get-MerakiSwitchPorts
Returns all of the switch ports for the device with a serial number of ABCD-1234-EFGH.

.EXAMPLE
Get-MerakiOrganizations -organizationId 1234 -apikey YOURAPIKEY | Get-MerakiNetworks -id N_1234 | Get-MerakiDevices -serial ABCD-1234-EFGH | Get-MerakiSwitchPorts -number 1
Returns port #1 from the device with a serial number of ABCD-1234-EFGH.

#>
function Get-MerakiSwitchPorts {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [string]
        $serial,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [int]
        $number,
        
        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI
    )


    begin {

        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }
        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }
    }

    process {
        
        if ($number) {
            $ports = Get-MerakiAPICall -uriStem "/devices/$($serial)/switchPorts/$($number)" 
            $ports
        } else {
            $ports = Get-MerakiAPICall -uriStem "/devices/$($serial)/switchPorts" 
            $ports
        }
        
    }

}

<#
.SYNOPSIS
Get all of the VLANS for an organization (Firewall)

.PARAMETER networkId
(REQUIRED)  Get all the VLANS for the specified network.  This is one of the inconsistancies present in the API.  The id for the network is returned as ID not NETWORKID so without some changes the pipeline isn't directly supported by property name.  You could use an alias or change all of the methods such that the 'id' is prefixed with the object type like networkid, vlanid, etc.  Database admins also argue about the identity field as to whether or not it should be just id or tableid.

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Get-MerakiVLANS -networkId N_1234
Returns all of the VLANS for the N_1234 network.

.EXAMPLE
Get-MerakiVLANS -networkId N_1234 -id 10
Returns VLAN 10 for network N_1234.

#>
function Get-MerakiVLANS {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]
        $networkId,

        [parameter(Mandatory=$false)]
        [int]
        $id,

        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI
    )


    begin {

        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }
        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }
    }

    Process {
        if ($id) {
            Get-MerakiAPICall -uriStem "/networks/$($networkId)/vlans/$(id)" 
        } else {
            Get-MerakiAPICall -uriStem "/networks/$($networkId)/vlans" 
        }
        
    }

}

<#
.SYNOPSIS
Get all the SSIDS for the network specified by the network id, optionally get a single SSID using the number parameter

.PARAMETER networkId
(REQUIRED)  Get all the SSIDS for the specified network

.PARAMETER number
(REQUIRED)  Get a specific SSID for the specified network

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Get-MerakiSSIDs -id N_1234
Returns all of the SSIDs for network N_1234.

.EXAMPLE
Get-MerakiSSIDs -id N_1234 -number 1
Returns SSID #1 from network N_1234.

#>
function Get-MerakiSSIDs {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [string]
        $id,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName, ParameterSetName="SINGLESSD")]
        [string]
        [ValidateRange(0,14)]
        $number,

        [parameter(Mandatory=$false)]
        [string]
        $apikey,

        [parameter(Mandatory=$false)]
        [switch]
        $displayURI

        )


    begin {

        if ($apikey) {
            $headers.'X-Cisco-Meraki-API-Key'                
        }
        while (-not($headers.'X-Cisco-Meraki-API-Key')) {
             Get-MerakiAPIKey             
        }
    }
    
    Process {

        if ($number) {
            $ssids = Get-MerakiAPICall -uriStem "/networks/$($id)/ssids/$($number)"     
            $ssids
        } else {
            $ssids = Get-MerakiAPICall -uriStem "/networks/$($id)/ssids"     
            $ssids
        }
        
    }

    

}


<#
.SYNOPSIS
This is the base PUT call that all GET cmdlets call.  This could be destructive, please test on a test network!!!

.PARAMETER uriStem

.PARAMETER body

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Set-MerakiAPICall -uriStem "/devices/ABCD-1234-EFGH" -body @{"tag"="hello"} -apikey YOURAPIKEY -displayuri
This will add a tag called hello to the device with a serial number of ABCD-1234-EFGH using YOURAPIKEY for the apikey and displaying the uristem to the console.  When I provisioned switches I defined multiple properties in the body so I passed a variable to the body parameter.


#>
function Set-MerakiAPICall {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)]
        [string]
        $uriStem,

        [parameter(Mandatory=$true)]
        [string]
        $body,
        
        [parameter(Mandatory=$false)]
        [string]
        $apikey
    ) 

        $uri =  "$($merakiAPI)$($uriStem)"    

        if ($displayURI) {
            Write-Host "PUT - $($uri)"     
        }
        
        $response = Invoke-WebRequest -Method Put -Uri $uri -Headers $headers -Body $body -MaximumRedirection 0 -ErrorAction Ignore

          
        if (DoesPropertyExist -MyObject $response -MyPropertyName StatusCode) {
            if ($response.StatusCode -ne 200) {
                Write-Host "PUT was redirected to: $($response.Headers.Location)"
                $response1 = Invoke-WebRequest -Method Put -Uri $response.Headers.Location -Headers $headers -Body $body
                if (DoesPropertyExist -MyObject $response1 -MyPropertyName StatusCode) {
                    $response1.Content | ConvertFrom-Json
                }
            } else {
                $response.Content | ConvertFrom-Json
            }
        }
        
}

<#
.SYNOPSIS
Used to set properties on SSID's.  This could be destructive, please test on a test network!!!!

.PARAMETER networkId
The specified network id for the SSID

.PARAMETER number
The SSID number as it appears in the dashboard

.PARAMETER body
PowerShell hash that will be converted to JSON.

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Set-MerakiSSIDs -networkId N_1234 -number 1 -body ($[PSCustomObject]@{"radiusServers"=@([PSCustomObject]@{"host"="1.1.1.1";"port"="1812";"secret"="RADIUSSECRET"},[PSCustomObject]@{"host"="2.2.2.2";"port"="1812";"secret"="RADIUSSECRET"})}|ConvertTo-Json)
Set the first SSID Radius Servers.  It would be better to create a variable to hold the body object and convert it to a json string instead of trying to pass it as a parameter.  Since this is an example I had to put it on one line.  This takes a PSCustomObject with one property called radiusServers which is an array of customobjects and converts it to json.

#>
function Set-MerakiSSIDs {
    [CmdletBinding()]
    param(
            [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
            [string]
            $networkId,

            [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
            [int]
            $number,

            [parameter(Mandatory=$true)]
            [string]
            $body,
        
            [parameter(Mandatory=$false)]
            [string]
            $apikey
        )


        $resp = Set-MerakiAPICall -uriStem "/networks/$($networkId)/ssids/$($number)" -body $body -ErrorAction Ignore 
        $resp

}


<#
.SYNOPSIS
Used to set properties on switch ports.  This could be destructive, please test on a test network!!!!

.PARAMETER serial
The specified network id for the SSID

.PARAMETER number
The SSID number as it appears in the dashboard

.PARAMETER body
PowerShell hash that will be converted to JSON.

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Set-MerakiSwitchPort -serial ABCD-1234-EFGH -number 1 -body ([PSCustomObject]@{"enabled"="true";"type"="trunk";"vlan"=1;"allowedVlans"="1,2,3,4,5,6,7";"poeEnabled"="true";"stpGuard"="disabled"}|ConvertTo-Json)
Set the first switch port on the switch with serial number BACD-1234-EFGH to a trunk port specifying native vlan, allowed vlans and disabling stpGuard

#>
function Set-MerakiSwitchPort {
    [CmdletBinding()]    
    Param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [string]
        $serial,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [int]
        $number,

        [parameter(Mandatory=$true)]
        [string]
        $body,
        
        [parameter(Mandatory=$false)]
        [string]
        $apikey

    )


    Process {
        $resp = Set-MerakiAPICall -uriStem "/devices/$($serial)/switchPorts/$($number)" -body $body -ErrorAction Ignore 
        $resp
    }

}

<#
.SYNOPSIS
Used to set properties on a device. This could be destructive, please test on a test network!!!!


.PARAMETER networkid
The specified network id for the device

.PARAMETER serial
The serial number of the device

.PARAMETER body
PowerShell hash that will be converted to JSON.

.PARAMETER apikey
(OPTIONAL)  Meraki API for this specific organization, THIS WILL BE SAVED in the header so any subsequent calls to the API will use this key unless you pass a different API Key

.EXAMPLE
Set-MerakiDevice -networkId N_1234 -serial ABCD-1234-EFGH -body ([PSCustomObject]@{"name"="DEVICENAME";"tags"="SOMETAG"}|ConvertTo-Json)
Set the device name and tags on device with serial ABCD-1234-EFGH on network with an id of N_1234.

#>
function Set-MerakiDevice {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]   
        [string]
        $networkId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]   
        [string]
        $serial,

        [parameter(Mandatory=$true)]
        [string]
        $body,
        
        [parameter(Mandatory=$false)]
        [string]
        $apikey

    )

        $resp = Set-MerakiAPICall -uriStem "/networks/$($networkId)/devices/$($serial)" -body $body -ErrorAction Ignore 
        $resp

}




<#

$org = Get-MerakiOrganizations -apikey YOURMERAKIAPIKEY
OR IF YOU HAVE MULTIPLE ORG ID's
$org = Get-MerakiOrganizations -organizationId YOURORGID -apikey YOURMERAKIAPIKEY

$networks = $org | Get-MerakiNetworks 
$network = $networks | where { $_.id -eq "L_1234" }
$devices = $network | Get-MerakiDevices
$switches = $devices | where { $_.model -like "MS*" }
$switchClients = Get-MerakiClients -serial ABCD-1234-EFGH
$switchPorts = Get-MerakiSwitchPorts -serial ABCD-1234-EFGH
$aps = $devices | where { $_.model -like "MR*" }

#>