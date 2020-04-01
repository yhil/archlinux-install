read -p "Domain name: " domainname
read -p "Domain controller: " domaincontroller
read -p "DNS domain name(s) (if many sperate with a space): " domainsearch
read -p "DNS server 1: " dns1
read -p "DNS server 2: " dns2
read -p "DNS server 3: " dns3
read -p "Computer Name:  " computername
read -p "Shell for domain users (e.g: bash, zsh): " shell

sudo pacman -S samba pam-krb5 ntp


cat > /etc/hosts << EOF 
search ${domainsearch}
nameserver $dns1
nameserver $dns2
nameserver $dns3
EOF

cat > /etc/ntp.conf << EOF
server ${domaincontroller}.${domainname}
server 0.arch.pool.ntp.org
server 1.arch.pool.ntp.org
server 2.arch.pool.ntp.org
server 3.arch.pool.ntp.org

restrict default kod limited nomodify nopeer noquery notrap
restrict 127.0.0.1
restrict ::1

driftfile /var/lib/ntp/ntp.drift
EOF

cat > /etc/krb5.conf << EOF


[libdefaults]
	default_realm	= ${domainname^^}
	clockskew	= 300
	ticket_lifetime = 1d
	forwardable	= true
	proxiable	= true
	dns_lookup_realm = true
	dns_lookup_kdc	= true

[realms]
# use "kdc = ..." if realm admins haven't put SRV records into DNS
	${domainname^^} = {
		kdc	= ${domaincontroller^^}.${domainname^^}
		admin_server = ${domaincontroller^^}.${domainname^^}
		default_domain = ${domainname^^}
	}

[domain_realm]
	.kerberos.server = ${domainname^^}
	.${domainname} = ${domainname^^}
	${domainname} = ${domainname^^}
	emea	= ${domainname^^}

[appdefaults]
	pam = {
	ticket_lifetime = 1d
	renew_lifetime = 1d
	forwardable = true
	proxiable = false
	retain_after_close = false
	minimum_uid = 0
	debug = false
	}

[logging]
	default = FILE:/var/log/krb5libs.log
	kdc	= FILE:/var/log/kdc.log
	admin_server	= FILE:/var/log/kadmind.log
EOF

cat > /etc/security/pam_winbind << EOF
[global]
  debug = no
  debug_state = no
  try_first_pass = yes
  krb5_auth = yes
  krb5_ccache_type = FILE
  cached_login = yes
  silent = no
  mkhomedir = yes
EOF

cat > /etc/samba/smb.conf << EOF
[Global]
  netbios name = ${computername}
  workgroup = WORKGROUP
  realm = ${domainname^^}
  server string = %h ArchLinux Host
  security = ads
  encrypt passwords = yes
  password server = ${domaincontroller}.${domainname}
  client signing = auto
  server signing = auto

  idmap config * : backend = tdb
  idmap config * : range = 10000-20000

  winbind use default domain = Yes
  winbind enum users = Yes
  winbind enum groups = Yes
  winbind nested groups = Yes
  winbind separator = +
  winbind refresh tickets = yes
  winbind offline logon = yes
  winbind cache time = 300

  template shell = /bin/${shell}
  template homedir = /home/%D/%U
   
  preferred master = no
  dns proxy = no
  wins server = ${domaincontroller}.${domainname}
  wins proxy = no

  inherit acls = Yes
  map acl inherit = Yes
  acl group control = yes

  load printers = no
  debug level = 3
  use sendfile = no
EOF


cat > /etc/nsswitch.conf << EOF
# Name Service Switch configuration file.
# See nsswitch.conf(5) for details.

passwd: files winbind 
group: files winbind
shadow: files winbind

publickey: files

hosts: files dns wins
networks: files

protocols: files
services: files
ethers: files
rpc: files

netgroup: files
EOF

cat > /etc/pam.d/system-auth << EOF
#%PAM-1.0

auth      [success=1 default=ignore] pam_localuser.so
auth	  [success=2 default=die] pam_winbind.so
auth 	  [success=1 default=die] pam_unix.so nullok
auth	  requisite pam_deny.so
auth      optional  pam_permit.so
auth      required  pam_env.so

account   required pam_unix.so
account   [success=1 default=ignore] pam_localuser.so
account   required pam_winbind.so
account   optional  pam_permit.so
account   required  pam_time.so

password  [success=1 default=ignore] pam_localuser.so
password  [success=2 default=die] pam_winbind.so
password [success=1 default=die] pam_unix.so sha512 shadow
password  requisite pam_deny.so
password  optional  pam_permit.so

session   required  pam_limits.so
session required pam_mkhomedir.so skel=/etc/skel umask=0022
session required pam_unix.so
session [success=1 default=ignore] pam_localuser.so
session required pam_winbind.so
session   optional  pam_permit.so
EOF

cat > /etc/pam.d/su << EOF
auth    required        pam_env.so
auth    sufficient      pam_winbind.so
auth    sufficient      pam_unix.so nullok
auth    required        pam_deny.so

account   sufficient pam_unix.so
account   sufficient pam_winbind.so

session sufficient pam_unix.so
session sufficient pam_winbind.so
EOF

sudo systemctl enable --now ntpd
sudo systemctl enable --now nmb
sudo systemctl enable --now smb
sudo systemctl enable --now winbind 
