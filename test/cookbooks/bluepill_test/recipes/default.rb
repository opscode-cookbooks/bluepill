include_recipe "bluepill"

# Boring
package "nc" do
  package_name case node['platform_family']
               when "debian"
                 "netcat"
               else
                 "nc"
               end
end

# This fake services uses Netcat to continuously send the secret
# (attribute) to the tcp_server_listen_port, which we bind in the test
template ::File.join(node['bluepill']['conf_dir'],
                     node['bluepill_test']['service_name'] + '.pill') do
  variables({
    :name => node['bluepill_test']['service_name'],
    :secret => node['bluepill_test']['secret'],
    :port => node['bluepill_test']['tcp_server_listen_port']
    })
end

bluepill_service node['bluepill_test']['service_name'] do
  action [:enable, :load, :start]
end

# Another fake service that does not use the default bluepill conf_dir
template ::File.join('/root', node['bluepill_test_with_conf_dir']['service_name'] + '.pill') do
  source 'test_app.pill.erb'
  variables({
    :name => node['bluepill_test_with_conf_dir']['service_name'],
    :secret => node['bluepill_test_with_conf_dir']['secret'],
    :port => node['bluepill_test_with_conf_dir']['tcp_server_listen_port']
    })
end

bluepill_service node['bluepill_test_with_conf_dir']['service_name'] do
  action [:enable, :load, :start]
  conf_dir '/root'
end
