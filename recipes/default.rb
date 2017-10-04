#
# Cookbook Name:: logdna_agent
# Recipe:: default
#
# Copyright 2016, Toby Sullivan
#
# All rights reserved
#


case node.platform
  when 'ubuntu','debian'
    apt_repository 'logdna' do
      uri        'http://repo.logdna.com'
      components ['stable', 'main']
      action     :add
      trusted    true
    end


  when 'redhat','centos','fedora','scientific','amazon','suse'
    yum_repository 'logdna' do
      description 'LogDNA Repo'
      baseurl 'http://repo.logdna.com/el6/'
      gpgcheck false
      enabled true
    end
end

execute 'run logdna-agent' do
  command "logdna-agent -k #{node['logdna_agent']['api_key']}"
  action  :nothing
end

package 'logdna-agent' do
  action   :install
  notifies :run, 'execute[run logdna-agent]', :immediately
end

if ::File.exists?("/etc/init.d/logdna-agent")
  case node.platform
    when 'ubuntu','debian'
      execute "update-rc.d logdna-agent defaults"

    when 'redhat','centos','fedora','scientific','amazon','suse'
      execute "chkconfig --add logdna-agent && chkconfig --level 2345 logdna-agent on"
  end
else
  Chef::Log.warn("Cannot enable service, init script does not exist")
end

node['logdna_agent']['log_directories'].each do |dir|
  execute "add #{dir} to logdna-agent" do
    command "logdna-agent -d #{dir}"
  end
end

unless node['logdna_agent']['log_files'].nil? || node['logdna_agent']['log_files'].empty?
  node['logdna_agent']['log_files'].each do |file|
    execute "add #{file} to logdna-agent" do
      command "logdna-agent -f #{file}"
    end
  end
end

unless node['logdna_agent']['exclude_files'].nil? || node['logdna_agent']['exclude_files'].empty?
  node['logdna_agent']['exclude_files'].each do |file|
    execute "exclude #{file} from logdna-agent" do
      command "logdna-agent -e #{file}"
    end
  end
end

unless node['logdna_agent']['hostname'].nil? || node['logdna_agent']['hostname'].empty?
  execute "add hostname to logdna-agent" do
    command "logdna-agent -n #{node['logdna_agent']['hostname']}"
  end
end

unless node['logdna_agent']['tags'].nil? || node['logdna_agent']['tags'].empty?
  execute "add tags to logdna-agent" do
    command "logdna-agent -t #{node['logdna_agent']['tags']}"
  end
end

service 'logdna-agent' do
  action :start
end
