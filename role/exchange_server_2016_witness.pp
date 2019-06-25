# Exchange 2016 Witness Server
#
class role::windows::exchange_server_2016_witness {
  include profile::windows::soebuild
  include profile::windows::exchange_server_witness

  Class['profile::windows::soebuild']
  -> Class['profile::windows::exchange_server_witness']
}
