require 'securerandom'

default['bluepill_test']['service_name'] = "test_app"
default['bluepill_test']['tcp_server_listen_port'] = 1234
default['bluepill_test']['secret'] = SecureRandom.uuid

default['bluepill_test_with_conf_dir']['service_name'] = "with_conf_dir_test_app"
default['bluepill_test_with_conf_dir']['tcp_server_listen_port'] = 1235
default['bluepill_test_with_conf_dir']['secret'] = SecureRandom.uuid
