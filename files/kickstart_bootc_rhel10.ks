<%#
kind: provision
name: Kickstart Default bootc - Trimmed
model: ProvisioningTemplate
oses:
- RedHat
-%>
<%
  # Variable setup for post scripts and container URL
  ostreecontainer = host_param('ostreecontainer')
-%>
# This kickstart file was rendered from the Foreman provisioning template "<%= @template_name %>".
lang <%= host_param('lang') || 'en_US.UTF-8' %>
selinux --<%= host_param('selinux-mode') || 'enforcing' %>
keyboard <%= host_param('keyboard') || 'us' %>
<%
# Network setup is essential for pulling the container and reporting to Foreman
@host.interfaces.reject{ |iface| iface.bmc? }.sort_by { |iface| (iface.bond? || iface.bridge?) ? 0 : iface.provision? ? 20 : 10 }.each do |iface|
-%>
<%= snippet(
      'kickstart_network_interface',
      variables: {
        iface: iface,
        host: @host,
        static: @static,
        static6: @static6
      }
    ) -%>
<%
end
-%>
<% if host_param('bootc_registry_auth_b64').present? -%>
%pre --erroronfail
REGISTRY="satellite1.savage.test"
mkdir -p "/etc/containers/certs.d/${REGISTRY}"
curl -sf "http://${REGISTRY}/pub/katello-server-ca.crt" \
  -o "/etc/containers/certs.d/${REGISTRY}/ca.crt"
mkdir -p /etc/ostree
cat > /etc/ostree/auth.json << 'EOF'
{
  "auths": {
    "satellite1.savage.test": {
      "auth": "<%= host_param('bootc_registry_auth_b64') %>"
    }
  }
}
EOF
%end
<% end -%>
# --- Core Installation ---
# 1. Set the container image as the installation source
ostreecontainer --url <%= ostreecontainer %>
# 2. Set the root password to make the system login-able
rootpw --iscrypted <%= root_pass %>
# 3. Allow SSH for remote login; assumes firewall is installed in container
firewall --service=ssh
# --- Time ---
timezone --utc <%= host_param('time-zone') || 'UTC' %>
<% if host_param('ntp-pools') -%>
<% host_param('ntp-pools').each do |ntppool| -%>
timesource --ntp-pool <%= ntppool %>
<% end -%>
<% elsif host_param('ntp-server') -%>
timesource --ntp-server <%= host_param('ntp-server') %>
<% end -%>
# --- Bootloader and Partitioning ---
# This assumes you are assigning a partition table in Foreman.
bootloader --location=mbr --append="<%= host_param('bootloader-append') || 'nofb quiet splash=quiet' %>" <%= grub_pass %>
<%= @host.diskLayout %>
# --- Finalize ---
text
skipx
reboot
# --- Post-Install Scripts ---
<%#
  Register with Satellite, enroll in IDM when the host has a realm,
  install Remote Execution keys, then signal Foreman that the build finished.
%>
%post
exec < /dev/tty3 > /dev/tty4
chvt 3
(
if [ ! -f /etc/resolv.conf ] || [ ! -s /etc/resolv.conf ]; then
  cat > /etc/resolv.conf << 'RESOLV_EOF'
<% if @host.domain -%>
search <%= @host.domain.name %>
<% end -%>
<% if @host.subnet -%>
<% [@host.subnet.dns_primary, @host.subnet.dns_secondary].compact.each do |nameserver| -%>
nameserver <%= nameserver %>
<% end -%>
<% end -%>
RESOLV_EOF
fi
# A debug section in case of DNS issues
# echo "=== DNS Configuration ==="
# cat /etc/resolv.conf
# echo "=== Testing DNS Resolution ==="
# nslookup cdn.redhat.com || echo "WARNING: Cannot resolve cdn.redhat.com"
# echo "=========================="
<%= snippet 'redhat_register' -%>
subscription-manager refresh
subscription-manager repos

<% if @host.realm && (@host.realm.realm_type == 'FreeIPA' || @host.realm.realm_type == 'Red Hat Identity Management') -%>
<%= snippet 'freeipa_register' -%>
<% else -%>
echo "Skipping freeipa_register: host has no IDM/FreeIPA realm assigned in Foreman"
<% end -%>

<%= snippet('remote_execution_ssh_keys') %>
touch /tmp/foreman_built
chvt 1
) 2>&1 | tee /root/install.post.log
%end
<%#
The last post section tells Foreman the build is complete.
%>
%post --erroronfail --log=/root/install-callhome.post.log
if test -f /tmp/foreman_built; then
  echo "calling home: build is done!"
  <%= indent(2, skip1: true, skip_content: 'EOF') { snippet('built', :variables => { :endpoint => 'built', :method => 'POST', :body_file => '/root/install.post.log' }) } -%>
else
  echo "calling home: build failed!"
  <%= indent(2, skip1: true, skip_content: 'EOF') { snippet('built', :variables => { :endpoint => 'failed', :method => 'POST', :body_file => '/root/install.post.log' }) } -%>
fi
sync
%end
