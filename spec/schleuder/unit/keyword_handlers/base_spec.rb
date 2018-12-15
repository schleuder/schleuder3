require 'spec_helper'

describe KeywordHandlers::Base do
  it 'stores mail, list and arguments as instance variables' do
    mail = Mail.new
    mail.list = create(:list)
    arguments = %w[1 2 3]
    instance = KeywordHandlers::Base.new(mail: mail, arguments: arguments)

    expect(instance.instance_variable_get('@mail')).to eql(mail)
    expect(instance.instance_variable_get('@list')).to eql(mail.list)
    expect(instance.instance_variable_get('@arguments')).to eql(arguments)
  end

  it 'provides methods to register keywords' do
    expect(KeywordHandlers::Base.methods).to include(:handles_list_keyword)
    expect(KeywordHandlers::Base.methods).to include(:handles_request_keyword)
  end
end
