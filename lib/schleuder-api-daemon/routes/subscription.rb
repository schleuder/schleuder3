class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/subscriptions' do
    get '.json' do
      filterkeys = Subscription.configurable_attributes + ['list_id', 'email']
      filter = params.select do |param|
        filterkeys.include?(param)
      end

      logger.debug "Subscription filter: #{filter.inspect}"
      if filter['list_id'] && ! is_an_integer?(filter['list_id'])
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
        # We don't have to care about nil-values, subscribe() does that for us.
        sub, msgs = list.subscribe(
          parsed_body['email'],
          parsed_body['fingerprint'],
          parsed_body['admin'],
          parsed_body['delivery_enabled'],
          find_key_material
        )
        set_x_messages(msgs)
        logger.debug "subcription: #{sub.inspect}"
        if sub.valid?
          logger.debug "Subscribed: #{sub.inspect}"
          # TODO: why redirect instead of respond with result?
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
      list = sub.list
      args = find_attributes_from_body(%w[email fingerprint admin delivery_enabled])
      fingerprint, messages = list.import_key_and_find_fingerprint(find_key_material)
      set_x_messages(messages)
      # For an already existing subscription, only update fingerprint if a
      # new one has been selected from the upload.
      if fingerprint.present?
        args["fingerprint"] = fingerprint
      end
      if sub.update(args)
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
end
