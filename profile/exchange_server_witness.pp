# Windows Exchange Server - Witness Only
#
# This profile installs configures a server to be the exchange Witness for DAG purposes
#
# @Param user
# @Param password
# @Param dag_witness_directory
# @Param exchange_subsystem_user
#
class profile::windows::exchange_server_witness (
  String $user,
  String $password,
  String $dag_witness_directory,
  String $exchange_subsystem_user,
) {

  # Make sure the Witness Folder Exists
  file { $dag_witness_directory:
    ensure => directory
  }

  # Add Exchange Trusted Subsystem to local administrators group
  dsc { 'local_admin_group':
    resource_name => 'Group',
    module        => 'PSDesiredStateConfiguration',
    properties    => {
      ensure           => 'Present',
      memberstoinclude => [$exchange_subsystem_user],
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

}
