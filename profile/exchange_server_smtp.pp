# Windows Exchange 2016 Server (SMTP) profile
#
# @param user
# @param password
# @param connectors
#
class profile::windows::exchange_server_smtp (
  String $user,
  String $password,
  Array $connectors,
) {

  # Add Receive Connectors
  $connectors.each | $index, $connector | {
    dsc { "connector_${index}":
      resource_name => 'xExchReceiveConnector',
      module        => 'xExchange',
      properties    => {
        ensure           => 'Present',
        identity         => "${trusted['hostname']}\\${connector['name']}",
        authmechanism    => $connector['authmechanism'],
        bindings         => $connector['bindings'],
        maxmessagesize   => $connector['maxmessagesize'],
        permissiongroups => $connector['permissiongroups'],
        remoteipranges   => $connector['remoteipranges'],
        transportrole    => $connector['transportrole'],
        usage            => $connector['usage'],
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

}


