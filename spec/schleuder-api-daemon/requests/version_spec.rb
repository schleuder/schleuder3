require 'helpers/api_daemon_spec_helper'

describe 'version' do
  it 'does not return the current schleuder version if not authorized' do
    get '/version.json'

    expect(last_response.status).to be 401
    expect(last_response.body).not_to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end

  it 'returns the current schleuder version if authorized' do
    authorize!

    get '/version.json'

    expect(last_response.status).to be 200
    expect(last_response.body).to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end
end
