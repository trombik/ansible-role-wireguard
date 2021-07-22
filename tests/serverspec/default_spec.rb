require "spec_helper"
require "serverspec"

port = 51_820
default_user = "root"
default_group = case os[:family]
                when "openbsd", "freebsd"
                  "wheel"
                else
                  "root"
                end
interfaces = [
  {
    ifname: "wg0",
    key: "LggCy5zq4Cmy7Fw4gPsudesTcKb36KW7GeBEEQSJ6ZI=",
    pub: "CSJxPoyivjwv4dInstD5kNFdUiLMYxp1Bk039mt4aRQ="
  },
  {
    ifname: "wg1",
    key: "OsV/ZUQscDUYsnjwY70zDL/sTZQVXGe9EtbwZnpEvro=",
    pub: "v2fTbie1LgMf5aFxjBEQhPLLi6jAp4gOOd0qKVEnqCM="
  }
]

interfaces.each do |interface|
  describe file "/etc/hostname.#{interface[:ifname]}" do
    it { should exist }
    it { should be_file }
    it { should be_mode 640 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/#{interface[:key]}/) }
  end

  # wg1: flags=8083<UP,BROADCAST,NOARP,MULTICAST> mtu 1420
  #	index 6 priority 0 llprio 3
  #	wgport 51820
  #	wgpubkey v2fTbie1LgMf5aFxjBEQhPLLi6jAp4gOOd0qKVEnqCM=
  #	wgpeer VtsiDVbjJUipmEdApgf0KpMSDW5cCzZ/GDej0n9VT0c=
  #		tx: 0, rx: 0
  #		wgaip 172.16.100.100/32
  #	groups: wg
  describe command "ifconfig #{interface[:ifname]}" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }

    its(:stdout) { should match(/^#{interface[:ifname]}:\s+flags=.*UP/) }
    its(:stdout) { should match(/^\s+wgpubkey\s+#{interface[:pub]}/) }
  end
end

# netstat -lnf inet -p udp
# Active Internet connections (only servers)
# Proto   Recv-Q Send-Q  Local Address          Foreign Address
# udp          0      0  *.51820                *.*
describe command "netstat -lnf inet -p udp" do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^udp\s+.*\*\.#{port}/) }
end
