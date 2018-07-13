require 'helpers/api_daemon_spec_helper'

describe 'status' do
  it 'returns status code 200' do
    get '/status.json'

    expect(last_response.status).to be 200
  end
end
