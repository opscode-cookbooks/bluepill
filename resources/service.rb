#
# Cookbook:: bluepill
# Resource:: service
#
# Copyright:: 2010-2017, Chef Software, Inc.
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

property :service_name, name_property: true
property :variables, Hash

action :start do
  unless service_running?
    converge_by("start #{new_resource.service_name}") do
      shell_out!(start_command)
    end
  end
end

action :enable do
  config_file = ::File.join(node['bluepill']['conf_dir'],
                            "#{new_resource.service_name}.pill")
  unless service_enabled?
    converge_by("enable #{new_resource.service_name}") do
      link "#{node['bluepill']['init_dir']}/#{new_resource.service_name}" do
        to node['bluepill']['bin']
        only_if { ::File.exist?(config_file) }
      end
      template_suffix = case node['platform_family']
                        when 'rhel', 'fedora', 'freebsd' then node['platform_family']
                        when 'debian' then 'lsb'
                        end

      template "#{node['bluepill']['init_dir']}/bluepill-#{new_resource.service_name}" do
        source "bluepill_init.#{template_suffix}.erb"
        cookbook 'bluepill'
        owner 'root'
        group node['bluepill']['group']
        mode '0755'
        variables(
          service_name: new_resource.service_name,
          config_file: config_file
        )
      end if template_suffix

      service "bluepill-#{new_resource.service_name}" do
        action [:enable]
      end
    end
  end
end

action :load do
  unless service_running?
    converge_by("load #{new_resource.service_name}") do
      shell_out!(load_command)
    end
  end
end

action :reload do
  converge_by("reload #{new_resource.service_name}") do
    shell_out!(stop_command) if service_running?
    shell_out!(load_command)
  end
end

action :disable do
  if service_running?
    converge_by("disable #{new_resource.service_name}") do
      file "#{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill" do
        action :delete
      end
      link "#{node['bluepill']['init_dir']}/#{new_resource.service_name}" do
        action :delete
      end
    end
  end
end

action :stop do
  if service_running?
    converge_by("stop #{new_resource.service_name}") do
      shell_out!(stop_command)
    end
  end
end

action :restart do
  if service_running?
    converge_by("restart #{new_resource.service_name}") do
      Chef::Log.debug "Restarting #{new_resource.service_name}"
      shell_out!(restart_command)
      Chef::Log.debug "Restarted #{new_resource.service_name}"
    end
  end
end

action_class do
  def status_command
    "#{node['bluepill']['bin']} #{new_resource.service_name} status"
  end

  def load_command
    "#{node['bluepill']['bin']} load #{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill"
  end

  def start_command
    "#{node['bluepill']['bin']} #{new_resource.service_name} start"
  end

  def stop_command
    "#{node['bluepill']['bin']} #{new_resource.service_name} stop"
  end

  def restart_command
    "#{node['bluepill']['bin']} #{new_resource.service_name} restart"
  end

  def service_running?
    if shell_out(status_command).exitstatus == 0
      Chef::Log.debug("#{new_resource.service_name} is running")
      true
    else
      Chef::Log.debug("#{new_resource.service_name} is not running")
      false
    end
  rescue SystemCallError
    false
  end

  def service_enabled?
    ::File.exist?("#{node['bluepill']['conf_dir']}/#{new_resource.service_name}.pill") &&
      ::File.symlink?("#{node['bluepill']['init_dir']}/#{new_resource.service_name}")
  end
end
