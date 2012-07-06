# Here are packages cobbler needs to have to work correctly

package "cobbler" do
  action :install
  response_file "cobbler.seed"
end

package "cobbler-web" do
  action :install
end

package "tftpd-hpa" do
  action :install
end

package "dnsmasq" do
  action :install
end

service "cobbler" do
  supports :restart => true 
  action :start
end

service "dnsmasq" do
  supports :restart => true 
  action :start
end

template "/etc/cobbler/modules.conf" do
  source "modules.conf.erb"
  mode 0644
  notifies :restart, ["service[cobbler]", "service[dnsmasq]"]
end

template "/etc/cobbler/settings" do
  source "settings.erb"
  mode 0644
  variables(
            :next_server => node["cobbler"]["next_server"],
            :server => node["cobbler"]["server"]
  )
  notifies :restart, "service[cobbler]"
end

execute "cobbler_sync" do
  command "cobbler sync"
  returns [0,155]
  action :nothing
end

template "/etc/cobbler/dnsmasq.template" do
  source "dnsmasq.template.erb"
  mode 0644
  variables(
            :dhcp_range => node["cobbler"]["dhcp_range"],
            :gateway => node["cobbler"]["gateway"]
            )
  notifies :run, "execute[cobbler_sync]"
end

template "/etc/cobbler/pxe/pxedefault.template" do
  source "pxedefault.template.erb"
  mode 0644
  variables(
            :pxetimeout => node["cobbler"]["pxetimeout"]
            )
  notifies :run, "execute[cobbler_sync]" 
end

template "/etc/cobbler/power/power_ssh.template" do
  source "power_ssh.template"
  mode 0644
end

directory node["cobbler"]["ks_mirror_dir"] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

include_recipe "cobbler::bootstrap"
include_recipe "cobbler::precise-x86_64"
include_recipe "cobbler::centos-6.2-x86_64"


# FIXME
# TO WORK CORRECTLY COBBLER NEEDED TO BE RESTRTED AND RESYNCED
# ruby_block "notify cobbler sync" do
#   block {}
#   notifies :run, "execute[cobbler_sync]"
# end
