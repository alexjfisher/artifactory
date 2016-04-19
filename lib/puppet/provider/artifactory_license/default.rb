require 'open-uri'

# Synchronized an artifatory repository by name to a destination
Puppet::Type.type(:artifactory_license).provide(:default) do
  desc "Installs a license on Artifactory."

  def is_valid_license(url, user_name, password_hash, ignore_unauthorized)
    # Number of retries in case service is down
    tries ||= 6

    license_url = url + '/api/system/license'

    begin
      response = open(license_url, http_basic_authentication: [user_name, password_hash])

      if response.status[0] == '404'
        raise Puppet::Error, 'Resource not found'
      end
    rescue Exception => e
      if (tries -= 1) > 0
        sleep(10)
        retry
      else
        raise Puppet::Error, 'Artifactory does not seem to be available'
      end
    end
    
    if response.status[0] == '401'
      # This only matters if we do not ignore_unauthorized
      if ignore_unauthorized
        return true
      else
        raise Puppet::Error, 'You do not have permission to access ' + url
      end
    elsif response.status[0] == '200'
      # For now just check for a validThrough value
      if JSON.parse(response.read)['validThrough'] == ''
        return false
      else
        return true
      end
    else
      raise Puppet::Error, 'Unknown status ' + response.status[0]
    end
  end

  def add_license(url, license, user_name, password)
    license_url = url + '/api/system/license'

    uri_post = URI.parse(license_url)
    http_post = Net::HTTP.new(uri_post.host, uri_post.port)

    request_post = Net::HTTP::Post.new(uri_post.request_uri)

    request_post["Content-Type"] = "application/json"
    request_post.basic_auth user_name, password
    request_post.body = '{"licenseKey": "' + license + '"}'

    response = http_post.request(request_post)

    case response
    when Net::HTTPSuccess
      return response
    else
      message = JSON.parse(response.body)['message']
      raise Puppet::Error, message
    end
  end

  #
  def exists?
    # Assign variables assigned by parameters
    artifactory_url     = resource[:name]

    license             = @resource.value(:license)
    user                = @resource.value(:user)
    password            = @resource.value(:password)
    ignore_unauthorized = @resource.value(:ignore_unauthorized)

    is_valid_license(artifactory_url, user, password, ignore_unauthorized)
  end

  # Delete all directories and files under destination
  def destroy
    raise Puppet::Error, 'You cannot remove an Artifactory license'
  end

  def create
    # Assign variables assigned by parameters
    artifactory_url     = resource[:name]

    license             = @resource.value(:license)
    user                = @resource.value(:user)
    password            = @resource.value(:password)

    add_license(artifactory_url, license, user, password)
  end
end