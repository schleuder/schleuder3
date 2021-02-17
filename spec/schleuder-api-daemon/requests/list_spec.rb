require 'helpers/api_daemon_spec_helper'

describe 'lists via api' do
  it 'creates a list' do
    authorize!
    list = create(:list)
    parameters = {
      email: 'new_testlist@example.com',
      fingerprint: list.fingerprint
    }
    expect {
      post '/lists.json', parameters.to_json
      expect(last_response.status).to be 200
    }.to change { List.count }.by 1
  end

  it 'shows a list' do
    authorize!
    list = create(:list)
    get "lists/#{list.id}.json"
    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'correctly finds a list by email-address that starts with a number' do
    authorize!
    list = create(:list, email: '9list@hostname')
    get "lists/#{list.email}.json"
    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

end
