# == Class artifactory::config
#
# This class is called from artifactory for service config.
#
class artifactory::config {
  # Install storage.properties if Available
  if(
    $::artifactory::jdbc_driver_url or
    $::artifactory::db_url or
    $::artifactory::db_username or
    $::artifactory::db_password or
    $::artifactory::db_type) {
      if (($::artifactory::jdbc_driver_url or $::artifactory::manage_jdbc_driver == false) and
      $::artifactory::db_url and
      $::artifactory::db_username and
      $::artifactory::db_password and
      $::artifactory::db_type
      ) {
        file { "${::artifactory::artifactory_home}/etc/storage.properties":
          ensure  => file,
          content => epp(
            'artifactory/storage.properties.epp',
            {
              db_url                         => $::artifactory::db_url,
              db_username                    => $::artifactory::db_username,
              db_password                    => $::artifactory::db_password,
              db_type                        => $::artifactory::db_type,
              binary_provider_type           => $::artifactory::binary_provider_type,
              pool_max_active                => $::artifactory::pool_max_active,
              pool_max_idle                  => $::artifactory::pool_max_idle,
              binary_provider_cache_maxSize  => $::artifactory::binary_provider_cache_maxSize,
              binary_provider_filesystem_dir => $::artifactory::binary_provider_filesystem_dir,
              binary_provider_cache_dir      => $::artifactory::binary_provider_cache_dir,
            }
          ),
          mode    => '0664',
        }

        if $::artifactory::manage_jdbc_driver {
          $file_name = regsubst($::artifactory::jdbc_driver_url, '.+\/([^\/]+)$', '\1')

          ::wget::fetch { $::artifactory::jdbc_driver_url:
            destination => "${::artifactory::artifactory_home}/tomcat/lib/",
          }

          file {"${::artifactory::artifactory_home}/tomcat/lib/${file_name}":
            ensure  => file,
            mode    => '0775',
            require => ::Wget::Fetch[$::artifactory::jdbc_driver_url],
          }
        }
      }
      else {
        warning('Database port, hostname, username, password and type must be all be set, or not set. Install proceeding without storage.')
      }
    }
}
