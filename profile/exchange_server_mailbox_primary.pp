# Windows Exchange 2016 Server (Primary Mailbox/Client Access) profile
#
# @Param user
# @Param password
# @Param folders_to_create
# @Param db_file
# @Param db_name
# @Param db_delete_retention
# @Param db_warning_quota
# @Param db_prohibit_send_quota
# @Param db_prohibit_receive_quota,
# @Param log_path,
# @Param certificate_file,
# @Param certificate_thumbprint
# @Param certificate_pfx_password
# @Param dag_name
# @Param dag_total_servers
# @Param dag_ip_addresses
# @Param dag_witness_server
# @Param dag_witness_directory
# @Param dag_network_mapi_name
# @Param dag_network_mapi_replication_enabled
# @Param dag_network_mapi_subnets
# @Param dag_network_repl_name
# @Param dag_network_repl_replication_enabled
# @Param dag_network_repl_subnet
#
class profile::windows::exchange_server_mailbox_primary (
  String $user,
  String $password,
  Array $folders_to_create,
  String $db_file,
  String $db_name,
  String $db_delete_retention,
  String $db_warning_quota,
  String $db_prohibit_send_quota,
  String $db_prohibit_receive_quota, 
  String $log_path, 
  String $certificate_file, 
  String $certificate_thumbprint,
  String $certificate_pfx_password,
  String $dag_name,
  Integer $dag_total_servers,
  Array $dag_ip_addresses,
  String $dag_witness_server,
  String $dag_witness_alternative_server,
  String $dag_witness_directory,
  String $dag_network_mapi_name,
  Boolean $dag_network_mapi_replication_enabled,
  Array $dag_network_mapi_subnets,
  String $dag_network_repl_name,
  Boolean $dag_network_repl_replication_enabled,
  Array $dag_network_repl_subnets,
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

  # Create the DAG
  dsc { 'create_dag':
    resource_name => 'xExchDatabaseAvailabilityGroup',
    module        => 'xExchange',
    properties    => {
      name                                 => $dag_name,
      datacenteractivationmode             => 'DagOnly',
      autodagtotalnumberofservers          => $dag_total_servers,
      databaseavailabilitygroupipaddresses => $dag_ip_addresses,
      manualdagnetworkconfiguration        => true,
      replaylagmanagerenabled              => true,
      skipdagvalidation                    => true,
      witnessdirectory                     => $dag_witness_directory,
      alternatewitnessdirectory            => $dag_witness_directory,
      witnessserver                        => $dag_witness_server,
      alternatewitnessserver               => $dag_witness_alternative_server,
      credential                           => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['exchange_certificate', 'add_failover_clustering'],
  }



  # Add server to DAG
  dsc { 'join_dag':
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
    require       => Dsc['create_dag', 'add_failover_clustering'],
  }


  # Create DAG Network (MAPI)
  dsc { 'dag_network_mapi':
    resource_name => 'xExchDatabaseAvailabilityGroupNetwork',
    module        => 'xExchange',
    properties    => {
      name                      => $dag_network_mapi_name,
      databaseavailabilitygroup => $dag_name,
      ensure                    => 'present',
      replicationenabled        => $dag_network_mapi_replication_enabled,
      subnets                   => $dag_network_mapi_subnets,
      credential                => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['join_dag'],
  }


  # Create DAG Network (REPL)
  dsc { 'dag_network_repl':
    resource_name => 'xExchDatabaseAvailabilityGroupNetwork',
    module        => 'xExchange',
    properties    => {
      name                      => $dag_network_repl_name,
      databaseavailabilitygroup => $dag_name,
      ensure                    => 'present',
      replicationenabled        => $dag_network_repl_replication_enabled,
      subnets                   => $dag_network_repl_subnets,
      credential                => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => Dsc['join_dag'],
  }

  # Make sure the folders Exists to create the DB and LOG
  file { $folders_to_create:
    ensure => directory
  }

  # Create the DB on the primary node
  dsc { "db_${db_name}":
    resource_name => 'xExchMailboxDatabase',
    module        => 'xExchange',
    properties    => {
      name                     => $db_name,
      edbfilepath              => $db_file,
      logfolderpath            => $log_path,
      server                   => $trusted['hostname'],
      circularloggingenabled   => false,
      databasecopycount        => $dag_total_servers,
      deleteditemretention     => $db_delete_retention,
      issuewarningquota        => $db_warning_quota,
      prohibitsendquota        => $db_prohibit_send_quota,
      prohibitsendreceivequota => $db_prohibit_receive_quota,
      allowservicerestart      => true,
      credential               => {
        dsc_type       => 'MSFT_Credential',
        dsc_properties => {
          'user'     => $user,
          'password' => $password
        },
      },
    },
    require       => File[$folders_to_create],
  }

}




