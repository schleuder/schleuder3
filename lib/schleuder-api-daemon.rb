#!/usr/bin/env ruby

# Make sinatra use production as default-environment
ENV['RACK_ENV'] ||= 'production'

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'
require 'thin'
require_relative '../lib/schleuder.rb'


%w[tls_cert_file tls_key_file].each do |config_key|
  path = Conf.api[config_key]
  if ! File.readable?(path)
    $stderr.puts "Error: '#{path}' is not a readable file (from #{config_key} in config)."
    exit 1
  end
end

class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace
  use Rack::Auth::Basic, "Schleuder API Daemon" do |username, key|
    username == 'schleuder' && Conf.api_valid_api_keys.include?(key)
  end

  configure do
    set :server, :thin
    set :port, Schleuder::Conf.api['port'] || 4443
    set :bind, Schleuder::Conf.api['host'] || 'localhost'
    if settings.development?
      set :logging, Logger::DEBUG
    else
      set :logging, Logger::WARN
    end
  end

  before do
    cast_param_values
  end

  after do
    # Return connection to pool after each request.
    ActiveRecord::Base.connection.close
  end

  error do
    exc = env['sinatra.error']
    logger.error "Error: #{env['sinatra.error'].message}"
    case exc
    when Errno::EACCES
      server_error(exc.message)
    else
      client_error(exc.to_s)
    end
  end

  error 404 do
    'Not found'
  end

  get '/status.json' do
    json status: :ok
  end

  get '/version.json' do
    json version: Schleuder::VERSION
  end

  helpers do
    def list(id_or_email=nil)
      if id_or_email.blank?
        if params[:list_id].present?
          id_or_email = params[:list_id]
        else
          client_error "Parameter list_id is required"
        end
      end
      if id_or_email.to_i == 0
        # list_id is actually an email address
        list = List.where(email: id_or_email).first
      else
        list = List.where(id: id_or_email).first
      end
      list || halt(404)
    end

    def subscription(id_or_email)
      if id_or_email.to_i == 0
        # Email
        if params[:list_id].blank?
          client_error "Parameter list_id is required when using email as identifier for subscriptions."
        else
          sub = list.subscriptions.where(email: id_or_email).first
        end
      else
        sub = Subscription.where(id: id_or_email.to_i).first
      end
      sub || halt(404)
    end

    def requested_list_id
      # ActiveResource doesn't want to use query-params with create(), so here
      # list_id might be included in the request-body.
      params['list_id'] || parsed_body['list_id'] || client_error('Need list_id')
    end

    def parsed_body
      @parsed_body ||= begin
          b = JSON.parse(request.body.read)
          logger.debug "parsed body: #{b.inspect}"
          b
        end
    end

    def server_error(msg)
      logger.warn msg
      halt(500, json(error: msg))
    end

    # TODO: unify error messages. This method currently sends an old error format. See <https://github.com/rails/activeresource/blob/d6a5186/lib/active_resource/base.rb#L227>.
    def client_error(obj_or_msg, http_code=400)
      text = case obj_or_msg
             when String, Symbol
               obj_or_msg.to_s
             when ActiveRecord::Base
               obj_or_msg.errors.full_messages
             else
               obj_or_msg
             end
      logger.error "Sending error to client: #{text.inspect}"
      halt(http_code, json(errors: text))
    end

    # poor persons type casting
    def cast_param_values
      params.each do |key, value|
        params[key] =
            case value
            when 'true' then true
            when 'false' then false
            when '0' then 0
            when value.to_i > 0 then value.to_i
            else value
            end
      end
    end

    def key_to_hash(key, include_keydata=false)
      hash = {
        fingerprint: key.fingerprint,
        email: key.email,
        expiry: key.expires,
        trust_issues: key.usability_issue
      }
      if include_keydata
        hash[:description] = key.to_s,
        hash[:ascii] = key.armored
      end
      hash
    end
  end

  namespace '/lists' do
    get '.json' do
      json List.all, include: :subscriptions
    end

    post '.json' do
      listname = parsed_body['email']
      fingerprint = parsed_body['fingerprint']
      adminaddress = parsed_body['adminaddress']
      adminkey = parsed_body['adminkey']
      list, messages = ListBuilder.new({email: listname, fingerprint: fingerprint}, adminaddress, adminkey).run
      if list.nil?
        client_error(messages, 422)
      elsif ! list.valid?
        client_error(list, 422)
      else
        if messages.present?
          headers 'X-Messages' => messages.join(' // ').gsub(/\n/, ' // ')
        end
        body json(list)
      end
    end

    get '/configurable_attributes.json' do
      json(List.configurable_attributes) + "\n"
    end

    post '/send_list_key_to_subscriptions.json' do
      json(result: list.send_list_key_to_subscriptions)
    end

    get '/new.json' do
      json List.new
    end

    get '/:id.json' do |id|
      json list(id)
    end

    put '/:id.json' do |id|
      list = list(id)
      if list.update(parsed_body)
        204
      else
        client_error(list)
      end
    end

    patch '/:id.json' do |id|
      list = list(id)
      if list.update(parsed_body)
        204
      else
        client_error(list)
      end
    end

    delete '/:id.json' do |id|
      list = list(id)
      if list.destroy
        200
      else
        client_error(list)
      end
    end
  end

  namespace '/subscriptions' do
    get '.json' do
      filterkeys = Subscription.configurable_attributes + [:list_id, :email]
      filter = params.select do |param|
        filterkeys.include?(param.to_sym)
      end

      logger.debug "Subscription filter: #{filter.inspect}"
      if filter['list_id'] && filter['list_id'].to_i == 0
        # Value is an email-address
        if list = List.where(email: filter['list_id']).first
          filter['list_id'] = list.id
        else
          status 404
          return json(errors: 'No such list')
        end
      end

      json Subscription.where(filter)
    end

    post '.json' do
      begin
        list = list(requested_list_id)
        sub = list.subscribe(
            parsed_body['email'],
            parsed_body['fingerprint'],
            parsed_body['admin'],
            parsed_body['delivery_enabled']
          )
        logger.debug "subcription: #{sub.inspect}"
        if sub.valid?
          logger.debug "Subscribed: #{sub.inspect}"
          redirect to("/subscriptions/#{sub.id}.json"), 201
        else
          client_error(sub, 422)
        end
      rescue ActiveRecord::RecordNotUnique
        logger.error "Already subscribed"
        status 422
        json errors: {email: ['is already subscribed']}
      end
    end

    get '/configurable_attributes.json' do
      json(Subscription.configurable_attributes) + "\n"
    end

    get '/new.json' do
      json Subscription.new
    end

    get '/:id.json' do |id|
      json subscription(id)
    end

    put '/:id.json' do |id|
      sub = subscription(id)
      if sub.update(parsed_body)
        200
      else
        client_error(sub, 422)
      end
    end

    patch '/:id.json' do |id|
      sub = subscription(id)
      if sub.update(parsed_body)
        200
      else
        client_error(sub)
      end
    end

    delete '/:id.json' do |id|
      if sub = subscription(id).destroy
        200
      else
        client_error(sub)
      end
    end
  end

  namespace '/keys' do
    get '.json' do
      keys = list.keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys
    end

    post '.json' do
      input = parsed_body['keymaterial']
      if ! input.match('BEGIN PGP')
        input = Base64.decode64(input)
      end
      json list(requested_list_id).import_key(input)
    end

    get '/check_keys.json' do
      json result: list.check_keys
    end

    get '/:fingerprint.json' do |fingerprint|
      if key = list.key(fingerprint)
        json key_to_hash(key)
      else
        404
      end
    end

    delete '/:fingerprint.json' do |fingerprint|
      if list.delete_key(fingerprint)
        200
      else
        404
      end
    end
  end

  def self.run!
    super do |server|
      server.ssl = true
      server.ssl_options = {
        :cert_chain_file  => Conf.api['tls_cert_file'],
        :private_key_file => Conf.api['tls_key_file']
      }
    end
  end
end
