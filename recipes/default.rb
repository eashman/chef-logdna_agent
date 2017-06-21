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
    if ::File.exists?("/etc/init.d/logdna-agent")
      execute "update-rc.d logdna-agent defaults"
    else
      Chef::Log.warn("Cannot enable service, init script does not exist")
    end

  when 'redhat','centos','fedora','scientific','amazon','suse'
    yum_repository 'logdna' do
      description 'LogDNA Repo'
      baseurl 'http://repo.logdna.com/el6/'
      gpgcheck false
      enabled true
    end
    if ::File.exists?("/etc/init.d/logdna-agent")
      execute "chkconfig --add logdna-agent && chkconfig --level 2345 logdna-agent on"
    else
      Chef::Log.warn("Cannot enable service, init script does not exist")
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

node['logdna_agent']['log_directories'].each do |dir|
  execute "add #{dir} to logdna-agent" do
    command "logdna-agent -d #{dir}"
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
