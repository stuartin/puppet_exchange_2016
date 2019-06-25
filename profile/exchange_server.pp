# Windows Exchange Server - Base Installation and Configuration
#
# This profile installs the Exchange Server on Windows machines.
#
# @Param installation_iso_path
# @Param installation_iso_drive_letter
# @Param organization_name, 
# @Param user
# @Param password
# @Param product_key
# @Param certificate_file, # Used in child profile
# @Param certificate_thumbprint, # Used in child profile
# @Param certificate_pfx_password, # Used in child profile
#
class profile::windows::exchange_server (
  String $installation_iso_path,
  String $installation_iso_drive_letter,
  String $organization_name,
  String $user,
  String $password,
  String $product_key,
  String $certificate_file, # Used in child profiles
  String $certificate_thumbprint, # Used in child profiles
  String $certificate_pfx_password, # Used in child profiles
) {

  # Install Windows features
  $windowsfeatures = ['NET-Framework-45-Features',
                      'NET-WCF-HTTP-Activation45',
                      'RPC-over-HTTP-proxy',
                      'RSAT-Clustering',
                      'RSAT-Clustering-CmdInterface',
                      'RSAT-Clustering-Mgmt',
                      'RSAT-Clustering-PowerShell',
                      'WAS-Process-Model',
                      'Web-Asp-Net45',
                      'Web-Basic-Auth',
                      'Web-Client-Auth',
                      'Web-Digest-Auth',
                      'Web-Dir-Browsing',
                      'Web-Dyn-Compression',
                      'Web-Http-Errors',
                      'Web-Http-Logging',
                      'Web-Http-Redirect',
                      'Web-Http-Tracing',
                      'Web-ISAPI-Ext',
                      'Web-ISAPI-Filter',
                      'Web-Lgcy-Mgmt-Console',
                      'Web-Metabase',
                      'Web-Mgmt-Console',
                      'Web-Mgmt-Service',
                      'Web-Net-Ext45',
                      'Web-Request-Monitor',
                      'Web-Server',
                      'Web-Stat-Compression',
                      'Web-Static-Content',
                      'Web-Windows-Auth',
                      'Web-WMI',
                      'Windows-Identity-Foundation',
                      'RSAT-ADDS']

  $windowsfeatures.each | String $windowsfeature | {
    dsc { "add_${windowsfeature}":
      resource_name => 'WindowsFeature',
      module        => 'PSDesiredStateConfiguration',
      properties    => {
        ensure => 'Present',
        name   => $windowsfeature,
      },
    }
  }

  # Add user to local administrators group
  dsc { 'local_admin_group':
    resource_name => 'Group',
    module        => 'PSDesiredStateConfiguration',
    properties    => {
      ensure           => 'Present',
      memberstoinclude => [$user],
      groupname        => 'Administrators',
      credential       => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Install UCMA4
  package { 'UCMA4':
    ensure => '5.0.20150601.0',
  }

  # Install dotNet471
  package { 'dotnet471':
    ensure => present,
    name   => 'dotnet4.7.1',
  }

  # Install Visual C++ 2013 Redist
  package { 'vcredist2013':
    ensure => present,
    name   => 'vcredist2013',
  }

  # Install xExchange Module
  package { 'xExchange':
    ensure => '1.26.0.0',
  }

  # Install cUserRightsAssignment (DSC Requires Logon as Batch Right)
  package { 'cUserRightsAssignment':
    ensure => '1.0.2',
  }

  # Ensure the account has the logon as batch right (xExchInstall uses scheduled tasks to run)
  dsc { 'userrights_assignment':
    resource_name => 'cUserRight',
    module        => 'cUserRightsAssignment',
    properties    => {
      ensure    => 'present',
      constant  => 'seBatchLogonRight',
      principal => $user,
    },
    require       => Package['cUserRightsAssignment'],
  }

  # Reboot after installing features
  reboot { 'before_install':
    message => 'Puppet has requested a reboot to finish installing windows features.',
    timeout => 0,
    require => [
      Package['cUserRightsAssignment','xExchange','dotnet471','UCMA4','vcredist2013'],
      Dsc['userrights_assignment'],
    ],
  }

  # Mount the Exchange setup ISO
  mount_iso { $installation_iso_path:
    drive_letter => $installation_iso_drive_letter,
    notify       => Dsc['install_exchange'],
    require      => Reboot['before_install'],
  }

  # Install Exchange
  dsc { 'install_exchange':
    resource_name => 'xExchInstall',
    module        => 'xExchange',
    properties    => {
      path       => "${$installation_iso_drive_letter}:/Setup.exe",
      arguments  => "/IAcceptExchangeServerLicenseTerms /Mode:Install /Role:Mailbox /OrganizationName:${organization_name}",
      credential => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Mount_iso[$installation_iso_path],
    notify        => Reboot['post_install']
  }

  # Reboot after installing exchange
  reboot { 'post_install':
    message => 'Puppet has requested a reboot to finish installing exchange.',
    timeout => 0,
  }

  # Unmount the iso after installation
  exec { 'unmount_iso':
    provider => powershell,
    command  => "Dismount-DiskImage -ImagePath '${installation_iso_path}' -ErrorAction 'Stop'",
    onlyif   => "if ( (Get-DiskImage -ImagePath '${$installation_iso_path}').Attached ){ exit 1 } else { exit 0 }",
    require  => [
      Reboot['post_install'],
      Dsc['install_exchange'],
    ],
  }

  # License the Exchange Server
  dsc { 'config':
    resource_name => 'xExchExchangeServer',
    module        => 'xExchange',
    properties    => {
      identity            => $trusted['hostname'],
      productkey          => $product_key,
      allowservicerestart => true,
      credential          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['install_exchange'],
  }

  # Disable Malware Scanning
  dsc { 'malware':
    resource_name => 'xExchAntiMalwareScanning',
    module        => 'xExchange',
    properties    => {
      enabled    => false,
      credential => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['install_exchange'],
  }

}
