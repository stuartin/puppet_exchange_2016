# Exchange 2016 Windows server role (SMTP Server)
#
class role::windows::exchange_server_2016_smtp {
  include profile::windows::soebuild
  include profile::windows::exchange_server
  include profile::windows::exchange_server_smtp

  Class['profile::windows::soebuild']
  -> Class['profile::windows::exchange_server']
  -> Class['profile::windows::exchange_server_smtp']
}
