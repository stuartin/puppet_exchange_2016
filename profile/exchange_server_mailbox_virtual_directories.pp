# Windows Exchange 2016 Server (Mailbox/Client Access Virtual Directories) profile
#
# @param user
# @param password
# @param cas_site_scopes
# @param cas_internal_domain
# @param cas_external_domain
# @param cas_autodiscover_domain
#
class profile::windows::exchange_server_mailbox_virtual_directories (
  String $user,
  String $password,
  Array $cas_site_scopes,
  String $cas_internal_domain,
  String $cas_external_domain,
  String $cas_autodiscover_domain, 
) {

  # Setup CAS Server
  dsc { 'cas_server':
    resource_name => 'xExchClientAccessServer',
    module        => 'xExchange',
    properties    => {
      identity                       => $trusted['hostname'],
      autodiscoverserviceinternaluri => "https://${cas_autodiscover_domain}/autodiscover/autodiscover.xml",
      autodiscoversitescope          => $cas_site_scopes,
      credential                     => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS ActiveSync settings
  dsc { 'cas_activesync':
    resource_name => 'xExchActiveSyncVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity            => "${trusted['hostname']}\\Microsoft-Server-ActiveSync (Default Web Site)",
      basicauthenabled    => true,
      windowsauthenabled  => false,
      clientcertauth      => 'Ignore',
      externalurl         => "https://${cas_external_domain}/Microsoft-Server-ActiveSync",
      internalurl         => "https://${cas_internal_domain}/Microsoft-Server-ActiveSync",
      allowservicerestart => true,
      credential          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS ECP settings
  dsc { 'cas_ecp':
    resource_name => 'xExchEcpVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity                      => "${trusted['hostname']}\\ecp (Default Web Site)",
      basicauthentication           => true,
      windowsauthentication         => false,
      formsauthentication           => true,
      externalauthenticationmethods => ['Fba'],
      externalurl                   => "https://${cas_external_domain}/ecp",
      internalurl                   => "https://${cas_internal_domain}/ecp",
      allowservicerestart           => true,
      credential                    => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS MAPI settings
  dsc { 'cas_mapi':
    resource_name => 'xExchMapiVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity                 => "${trusted['hostname']}\\mapi (Default Web Site)",
      iisauthenticationmethods => ['Ntlm','OAuth','Negotiate'],
      externalurl              => '',
      internalurl              => "https://${cas_internal_domain}/mapi",
      allowservicerestart      => true,
      credential               => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS OAB settings
  dsc { 'cas_oab':
    resource_name => 'xExchOabVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity            => "${trusted['hostname']}\\OAB (Default Web Site)",
      externalurl         => "https://${cas_external_domain}/oab",
      internalurl         => "https://${cas_internal_domain}/oab",
      oabstodistribute    => ['Default Offline Address Book'],
      allowservicerestart => true,
      credential          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS OutlookAnywhere settings
  dsc { 'cas_outlook_anywhere':
    resource_name => 'xExchOutlookAnywhere',
    module        => 'xExchange',
    properties    => {
      identity                           => "${trusted['hostname']}\\rpc (Default Web Site)",
      iisauthenticationmethods           => ['Basic','Ntlm','Negotiate'],
      externalclientauthenticationmethod => 'Ntlm',
      externalclientsrequiressl          => true,
      internalclientauthenticationmethod => 'Ntlm',
      internalclientsrequiressl          => true,
      externalhostname                   => $cas_internal_domain,
      internalhostname                   => $cas_internal_domain,
      allowservicerestart                => true,
      credential                         => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS OWA settings
  dsc { 'cas_owa':
    resource_name => 'xExchOwaVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity                      => "${trusted['hostname']}\\owa (Default Web Site)",
      basicauthentication           => true,
      windowsauthentication         => false,
      formsauthentication           => true,
      externalauthenticationmethods => ['Fba'],
      externalurl                   => "https://${cas_external_domain}/owa",
      internalurl                   => "https://${cas_external_domain}/owa",
      allowservicerestart           => true,
      credential          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS PowerShell settings
  dsc { 'cas_powershell':
    resource_name => 'xExchPowerShellVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity                  => "${trusted['hostname']}\\PowerShell (Default Web Site)",
      basicauthentication       => false,
      windowsauthentication     => false,
      certificateauthentication => true,
      requiressl                => false,
      externalurl               => "https://${cas_external_domain}/PowerShell",
      internalurl               => "https://${cas_external_domain}/PowerShell",
      allowservicerestart       => true,
      credential                => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }

  # Setup CAS EWS settings
  dsc { 'cas_ews':
    resource_name => 'xExchWebServicesVirtualDirectory',
    module        => 'xExchange',
    properties    => {
      identity              => "${trusted['hostname']}\\EWS (Default Web Site)",
      basicauthentication   => true,
      windowsauthentication => true,
      externalurl           => "https://${cas_external_domain}/ews/exchange.asmx",
      internalurl           => "https://${cas_external_domain}/ews/exchange.asmx",
      allowservicerestart   => true,
      credential            => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
  }


}
