# Windows Exchange 2016 Server (Secondary Mailbox/Client Access) profile
#
# @param user
# @param password
# @param db_name
# @param certificate_file
# @param certificate_thumbprint
# @param certificate_pfx_password
# @param dag_name
#
class profile::windows::exchange_server_mailbox_secondary (
  String $user,
  String $password,
  String $db_name,
  String $certificate_file,
  String $certificate_thumbprint,
  String $certificate_pfx_password,
  String $dag_name,
) {

  # Ensure Failover Clustering is available
  dsc { 'add_failover_clustering':
    resource_name => 'WindowsFeature',
    module        => 'PSDesiredStateConfiguration',
    properties    => {
      ensure => 'Present',
      name   => 'Failover-Clustering',
    },
  }

  # Copy the certificate locally
  file { 'C:/Windows/System32/ExCert.pfx':
    source => $certificate_file
  }

  # Install the Exchange Certificate
  dsc { 'exchange_certificate':
    resource_name => 'xExchExchangeCertificate',
    module        => 'xExchange',
    properties    => {
      ensure             => 'present',
      allowextraservices => false,
      certfilepath       => 'C:/Windows/System32/ExCert.pfx',
      services           => ['IIS'],
      thumbprint         => $certificate_thumbprint,
      credential         => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
      certcreds          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => 'dummy',
          'password' => $certificate_pfx_password
        },
      },
    },
    require       => File['C:/Windows/System32/ExCert.pfx']
  }

  # Wait for the DAG to exist
  dsc { 'wait_for_dag':
    resource_name => 'xExchWaitForDAG',
    module        => 'xExchange',
    properties    => {
      identity   => $dag_name,
      credential => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['exchange_certificate']
  }

  # Add server to DAG
  dsc { 'add_dag_member':
    resource_name => 'xExchDatabaseAvailabilityGroupMember',
    module        => 'xExchange',
    properties    => {
      mailboxserver     => $trusted['hostname'],
      dagname           => $dag_name,
      skipdagvalidation => true,
      credential        => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['wait_for_dag']
  }

  # Wait for the Primary Mailbox Database to get created
  dsc { 'wait_for_db':
    resource_name => 'xExchWaitForMailboxDatabase',
    module        => 'xExchange',
    properties    => {
      identity   => $db_name,
      credential => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['add_dag_member']
  }

  # Create the DB copies the Secondary node/s
  dsc { "db_${db_name}":
    resource_name => 'xExchMailboxDatabaseCopy',
    module        => 'xExchange',
    properties    => {
      identity            => $db_name,
      mailboxserver       => $trusted['hostname'],
      replaylagtime       => '00:00:00',
      allowservicerestart => true,
      credential          => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['wait_for_db']
  }

}
