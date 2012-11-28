#
# Cookbook Name:: bluepill
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

gem_package "i18n"
gem_package "bluepill" do
  version node["bluepill"]["version"] if node["bluepill"]["version"]
end

[
  node["bluepill"]["conf_dir"],
  node["bluepill"]["pid_dir"],
  node["bluepill"]["state_dir"]
].each do |dir|
  directory dir do
    recursive true
    owner "root"
    group node["bluepill"]["group"]
  end
end

if File.exists?("/etc/rsyslog.conf")
  # Ensure the rsyslog service is known to chef
  service "rsyslog" do
    supports :start => true, :stop => true, :restart => true
    action :nothing
  end

  bluepill_log_line = "local6.*\t/var/log/bluepill.log"
  execute "setup rsyslog with bluepill" do
    command <<-SH
      echo "#{bluepill_log_line}" >> /etc/rsyslog.conf
    SH
    not_if "grep '#{bluepill_log_line}' /etc/rsyslog.conf"
    notifies :restart, "service[rsyslog]"
  end
end
