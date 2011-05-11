require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Local < ModCons::Configuration
end

describe ModCons::Configuration do
  
  describe "should build itself from a proper declaration" do

    before(:each) do
      @config = Local.declare(:config) do
        url 'http://example.com'
        credentials do
          username 'invalid_user'
          password 'invalid_pass'
        end
      end
    end
    
    it "should have the correct structure" do
      @config._keys.should include(:credentials,:url)
      @config.credentials._keys.should include(:password,:username)
    end
    
    it "should have the correct defaults" do
      @config.url.should == 'http://example.com'
    end
    
    it "should respond properly to #inspect" do
      match_data = @config.inspect.match(/#<Config: \{(url|credentials), (url|credentials)\}>/)
      match_data.should_not be_nil
      match_data.to_a.should include('url','credentials')
    end
    
    it "should include the configuration keys in the response to #methods" do
      @config.methods.should include('url', 'credentials')
    end
  end
    
  describe "should be configurable" do

    before(:each) do
      @config = Local.declare(:config) do
        url 'http://example.com'
        credentials do
          username 'invalid_user'
          password 'invalid_pass'
        end
      end
    end
    
    it "should be configurable in block notation" do
      @config.configure do
        url 'http://example.org'
        credentials do
          username 'valid_user'
          password 'valid_pass'
        end
      end
      @config.url.should == 'http://example.org'
      @config.credentials.username.should == 'valid_user'
      @config.credentials.password.should == 'valid_pass'
    end
    
    it "should be configurable in dot notation" do
      @config.configure do
        url 'http://example.org'
        credentials.username 'valid_user'
        credentials.password 'valid_pass'
      end
      @config.url.should == 'http://example.org'
      @config.credentials.username.should == 'valid_user'
      @config.credentials.password.should == 'valid_pass'
    end

    it "should be configurable in hash notation" do
      @config.configure({
        :url => 'http://example.org',
        :credentials => { :username => 'valid_user', :password => 'valid_pass' }
      })
      @config.url.should == 'http://example.org'
      @config.credentials.username.should == 'valid_user'
      @config.credentials.password.should == 'valid_pass'
    end
    
  end
  
  describe "should respond to its built-in instance methods" do
    
    before(:each) do
      @config = Local.declare(:config) do
        url 'http://example.com'
        credentials do
          username 'invalid_user'
          password 'invalid_pass'
        end
      end
    end

    it "should produce a valid configuration template" do
      @config = Local.declare(:config) do
        url 'http://example.com'
        credentials({ :username => 'invalid_user' })
      end
      @config.template.should == %{config.configure do\n  credentials({:username=>"invalid_user"})\n  url "http://example.com"\nend\n}
    end

    it "should produce a valid configuration hash" do
      @config.to_hash.should == { :url => 'http://example.com', :credentials => { :username => 'invalid_user', :password => 'invalid_pass' } }
    end

    it "should respond to []" do
      @config[:url].should == 'http://example.com'
      @config[:credentials].should == { :username => 'invalid_user', :password => 'invalid_pass' }
    end
    
    it "should call config_changed listeners when the configuration changes" do
      listener = mock('listener')

      @config.config_changed do |c|
        listener.process(c, c.url)
      end

      listener.should_not_receive(:process).with(@config, 'http://example.com')
      listener.should_receive(:process).with(@config, 'http://example.org').once
      listener.should_receive(:process).with(@config, 'http://example.net').once
    
      @config.configure { url 'http://example.com' } 
      @config.configure { url 'http://example.org' } 
      @config.configure { url 'http://example.net' } 
    end

  end
  
  describe "should raise appropriate errors and warnings" do
    
    before(:each) do
      @config = Local.declare(:config) do
        url 'http://example.com'
        credentials do
          username 'invalid_user'
          password 'invalid_pass'
        end
      end
    end
    
    it "should warn about a namespace redeclaration" do
      @config.stub!(:warn)
      @config.should_receive(:warn).with(/Redeclaring configuration namespace/).once
      @config.declare(:credentials) { cert nil }
    end
    
    it "should warn about a configuration option redeclaration" do
      @config.stub!(:warn)
      @config.should_receive(:warn).with(/Redeclaring configuration option/).once
      @config.declare { url 'http://example.org' }
    end

    it "should raise an exception when an unknown option is configured in block notation" do
      lambda {
        @config.configure do
          cert 'cert_file.cer'
        end
      }.should raise_error(NameError, /Unknown configuration option: cert/)
    end

    it "should raise an exception when an unknwon option is configured in hash notation" do
      lambda {
        @config.configure({ :cert => 'cert_file.cer' })
      }.should raise_error(NameError, /Unknown configuration option: cert/)
    end

    it "should raise an exception when too many arguments are passed during configuration" do
      lambda {
        @config.configure do
          url 'http://example.com', 'user', 'pass'
        end
      }.should raise_error(ArgumentError, /3 for 1/)
    end
    
    it "should raise an exception when an unknown option is accessed" do
      lambda {
        @config.credentials.pass
      }.should raise_error(NameError, /Unknown configuration option: pass/)
    end
    
  end
  
end
