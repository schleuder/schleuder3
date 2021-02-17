require 'spec_helper'

describe Schleuder::Conf do
  it 'reads ERB code in config files' do
    # Suppress warnings about already defined constants
    # if using "load" further below
    verbose_orig = $VERBOSE
    $VERBOSE = nil
    
    # Define constants
    val_old = 'val_old'

    # Check if env var is set
    if not ENV['SCHLEUDER_DB_PATH'].nil?
      val_old = ENV['SCHLEUDER_DB_PATH']
    end
   
    # Set env var, reload the config and check whether the correct value
    # is returned
    val_test = 'SCHLEUDER_ERB_TEST'
    ENV['SCHLEUDER_DB_PATH'] = val_test
    load 'schleuder/conf.rb' 
    expect(Schleuder::Conf.database['database']).to eql(val_test)

    # Reset the env var
    ENV['SCHLEUDER_DB_PATH'] = nil

    # Set the env var to the original value
    if val_old != 'val_old'
      ENV['SCHLEUDER_DB_PATH'] = val_old
    end
    
    load 'schleuder/conf.rb'

    # Set verbose level to original value
    $VERBOSE = $verbose_orig
  end
end
