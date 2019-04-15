require "spec_helper"

describe "a bounce message is received" do
  it "from bounce example" do
    start_smtp_daemon
    list = create(:list)
    list.subscribe("admin@example.org", nil, true)
    message_path = 'spec/fixtures/mails/bounce.eml'

    error = run_schleuder(:work, list.email, message_path)
    mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

    expect(error).to be_empty
    expect(mails.size).to eq 1

    stop_smtp_daemon
  end
end

