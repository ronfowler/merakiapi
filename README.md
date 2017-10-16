# merakiapi
This is a Powershell wrapper for the Meraki Cloud API.  The functions are designed around using the PowerShell pipeline.

Starting point:
1)  Enable the Dashboard API access that is listed under organization / settings.
2)  Copy the API Key it generates under your profile.  It will have a link after you enable the API.
3)  Install the modules, in PowerShell type help about_modules to find out how to install the module.  You'll need to find the module path for your user profile, create a folder called modules, create a folder called MerakiAPI and then copy the two files (MerakiAPI.PSM1 & MerakiAPI.PSD1) to that directory.
4)  Once the modules is installed you'll need to import the module:  import-module MerakAPI
5)  Verify the module is listed:  Get-Module
6)  View the available methods:  Get-Modules -name MerakiAPI | select -expandproperty ExportedCommands
7)  WARNING- DO NOT USE THE SET METHODS / COMMANDS UNLESS YOU UNDERSTAND WHAT YOU ARE DOING AND HAVE TESTED THEM ON A TEST NETWORK.

Below is how to use the GET Methods / COMMANDS
-------------------------------------------
First get your organization(s) id(s)

$org = Get-MerakiOrganizations -apikey PASTE_YOUR_API_KEY

If you have more than one organization you'll want to grab the organizationId from the org you are interested in and run the command again.

$org = Get-MerakiOrganizations -apikey PASTE_YOUR_API_KEY -organizationId YOUR_ORGANIZATION_ID

#Get your networks:

$networks = $org | Get-MerakiNetworks 

#Get the network you're interested in

$network = $networks | where { $_.name -eq "network_name" }

#Get the devices from that network

$devices = $network | Get-MerakiDevices

#Get just the switches

$switches = $devices | where { $_.model -like "MS*" }

#Get just the access points

$aps = $devices | where { $_.model -like "MR*" }

#Get the switch ports from a switch

$switchPorts = $switches | where { $_.name -eq "YOUR_SWITCH_NAME" } | Get-MerakiSwitchPorts

#You can dump the data at any point to a file

$switches | export-csv -notypeinformation -path c:\somedirectory\somefilename.csv

#Or you can view most of the columns in the PowerShell console

$switches | format-table

