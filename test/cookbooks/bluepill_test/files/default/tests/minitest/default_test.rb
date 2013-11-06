require_relative "./support/helpers"

describe_recipe 'bluepill_test::default' do
  include BluepillTestHelpers

  test_configs = [
    {:conf_dir => '/etc/bluepill', :key => 'bluepill_test', :args => {:action => [:enable, :load, :start]} },
    {:conf_dir => '/root', :key => 'bluepill_test_with_conf_dir', :args => {:action => [:enable, :load, :start], :conf_dir => '/root'} }]

  test_configs.each do |test_config|

    describe "create a bluepill configuration file" do
      let(:config) { file(::File.join(test_config[:conf_dir],
                                    node[test_config[:key]]['service_name'] +
                                    ".pill")) }
      it { config.must_exist }

      it "must be valid ruby" do
        assert(shell_out("ruby -c #{config.path}").exitstatus == 0)
      end
    end

    describe "runs the application as a service" do
      let(:service) do
        bluepill_service(
          node[test_config[:key]]['service_name'], test_config[:args])
      end
      it { service.must_be_enabled }
      it { service.must_be_running }
    end

    it "the default log file must exist (COOK-1295)" do
      file(node['bluepill']['logfile']).must_exist
    end

    describe "spawn a netcat tcp client repeatedly" do
      let(:port) { node[test_config[:key]]['tcp_server_listen_port'] }
      let(:secret) { node[test_config[:key]]['secret'] }
      it "should receive a TCP connection from netcat" do
        TCPServer.open("localhost", port) do |server|
          client = server.accept
          assert_instance_of TCPSocket, client

          client_secret = client.gets.strip!
          assert_equal secret, client_secret

          client.close
        end
      end
    end

  end

end
