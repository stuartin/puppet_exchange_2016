# Exchange Server Deployment and Management - Using xExchange DSC Module and Puppet
The profiles and roles within this repository can be applied to Windows Servers to install and configure all components in an Exchange Environment.
Code was written for Exchange 2016, however the xExchange DSC Module does support all versions

# Requirements
All the standard Microsoft Exchange Server 2016 requirements will need to be met
https://docs.microsoft.com/en-us/exchange/plan-and-deploy/system-requirements?view=exchserver-2016


## Service Account
- The credential used to install and manage Exchange must
  - If no Exchange Environment Exists (Enterprise Admin)
  - If existing Exchange Environment (Member of Organization Management)
  
## Puppet Requirements
- PFX file containing the Exchange Certificate must be included in puppet
- PuppetFile must include:
  - DSC Lite https://forge.puppet.com/puppetlabs/dsc_lite
  - Mount ISO https://forge.puppet.com/puppetlabs/mount_iso

## Packagement Manager (chocolatey) Requirements
- xExchange https://www.powershellgallery.com/packages/xExchange
- cUserRightsAssignment https://www.powershellgallery.com/packages/cUserRightsAssignment
- UCMA4 https://go.microsoft.com/fwlink/p/?linkId=258269
- .Net 4.7.1 https://go.microsoft.com/fwlink/p/?linkid=866906
- Visual C++ 2012 https://www.microsoft.com/download/details.aspx?id=30679

## Network Requirements
- All servers must be able to contact the CRL defined in the certificate
- All servers must have SMB access to the installation ISO
- SMB Access from Mailbox Servers to Witness Servers
- Any/Any Firewall Rules between Exchange Servers (Required for Microsoft Support)

## Virtual Machine Requirements
- All disks need to be present and formatted
- All network adapters need to be present and configured (MAPI and DAG adapters)

## AD Requirements
- DAG Creation may fail, if this is the case, pre-stage the DAG computer object https://docs.microsoft.com/en-us/exchange/high-availability/manage-ha/pre-stage-dag-cnos?view=exchserver-2016

# Roles
## Mailbox Server (Primary)
- Needs to be assigned to a single server
- Creates the DAG and initial database

## Mailbox Server (Secondary)
- Joins the existing DAG

## SMTP Server
- Used to manage Send/Receive Connectors

## Witness Server
- Used to monitor DAG quorum