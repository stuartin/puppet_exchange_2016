# Exchange 2016 Windows server role (Primary Mailbox Server)
#
class role::windows::exchange_server_2016_mailbox_primary {
  include profile::windows::soebuild
  include profile::windows::exchange_server
  include profile::windows::exchange_server_mailbox_primary
  include profile::windows::exchange_server_mailbox_virtual_directories

  Class['profile::windows::soebuild']
  -> Class['profile::windows::exchange_server']
  -> Class['profile::windows::exchange_server_mailbox_primary']
  -> Class['profile::windows::exchange_server_mailbox_virtual_directories']
}
