require 'helpers/api_daemon_spec_helper'

describe 'subscription via api' do

  before :each do
    @list = List.last || create(:list)
    @email = 'someone@localhost'
  end

  it 'doesn\'t subscribe new member without authorization' do
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json

    expect(last_response.status).to be 401
    expect(@list.reload.subscriptions.size).to be(0)
  end

  it 'subscribes new member to a list' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be false
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an admin user' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :admin => true}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be true
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an admin user with a truthy value' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :admin => '1'}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be true
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an user and unsets delivery flag' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :delivery_enabled => false}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be false
    expect(@list.subscriptions.first.delivery_enabled).to be false
  end

  it 'unsubscribes members' do
    subscription = create(:subscription, :list_id => @list.id)
    authorize!

    expect(@list.subscriptions.map(&:email)).to eql([subscription.email])

    delete "/subscriptions/#{subscription.id}.json"

    expect(last_response.status).to be 200
    expect(@list.reload.subscriptions.map(&:email)).to eql([])
  end
end
