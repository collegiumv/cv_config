.PHONY: site clean secrets mkdir_secrets ${SECRET_TARGETS} certreq

SECRETS_DIR = secret

SECRET_TARGETS = ${PLAIN_SECRETS}

PLAIN_SECRETS = account_salt \
	krb_db_enc_pass kdcAdmin_pass \
	nas_rsyncd_passwd \
	nut_monitor_passwd \
	slapd_acctService_password slapd_krbAdmService_password slapd_olcRootPW

DESTDIR = ${CURDIR}/tmp
SUDO = sudo
INSTALL = install

# OpenBSD UID and GID definitions
ROOT_U = 0
WHEEL_G = 0
NSD_G = 97

# -rw-r--r--
BIN1=	templates/etc/ntpd.conf \
	templates/etc/rc.conf.local \
	files/etc/dhcpd.conf \
	files/etc/pkg.conf \
	files/etc/rc.local \
	files/etc/rc.securelevel \
	files/etc/resolv.conf.boot \
	files/etc/resolv.conf.final \
	files/etc/sysctl.conf

# -rw-r-----
HOSTNAMES=	templates/etc/hostname.carp0 \
		templates/etc/hostname.carp1 \
		templates/etc/hostname.carp2 \
		templates/etc/hostname.em0 \
		templates/etc/hostname.em1 \
		templates/etc/hostname.em4 \
		templates/etc/hostname.pfsync0

site:
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}
	# In the OpenBSD Makefile this part is done by mtree but that doesn't exist on linux
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}/etc
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}/var/nsd
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${NSD_G} -m 750 ${DESTDIR}/var/nsd/etc
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}/var/nsd/zones
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}/var/unbound
	${SUDO} ${INSTALL} -d -o ${ROOT_U} -g ${WHEEL_G} -m 755 ${DESTDIR}/var/unbound/etc
	${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 550 install.site ${DESTDIR}
	cd roles/openbsd; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 644 files/etc/hosts ${DESTDIR}/etc/hosts.new; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 644 ${BIN1} ${DESTDIR}/etc; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 640 ${HOSTNAMES} ${DESTDIR}/etc; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 640 files/etc/mygate ${DESTDIR}/etc; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 600 files/etc/pf.conf ${DESTDIR}/etc; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${NSD_G} -m 640 files/var/nsd/etc/nsd.conf ${DESTDIR}/var/nsd/etc; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 644 files/var/nsd/zones/collegiumv.org ${DESTDIR}/var/nsd/zones; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 644 files/var/nsd/zones/42.168.192.in-addr.arpa ${DESTDIR}/var/nsd/zones; \
		${SUDO} ${INSTALL} -c -o ${ROOT_U} -g ${WHEEL_G} -m 644 templates/var/unbound/etc/unbound.conf ${DESTDIR}/var/unbound/etc;
	${SUDO} tar czf roles/preseed_site/files/site.tgz -C ${DESTDIR} .

clean:
	${SUDO} rm -rf ${DESTDIR}

secrets: mkdir_secrets ${SECRET_TARGETS}
	@tput setaf 1 && echo "Don't forget to get account_access.list and account_words.txt and edit account_admin_username and nslcd_bind_user" && tput sgr0

mkdir_secrets:
	mkdir -pm 0700 ${SECRETS_DIR}

${PLAIN_SECRETS}:
	export LC_CTYPE=C; tr -dc '!-~' < /dev/urandom | fold -w 32 | head -n 1 > ${SECRETS_DIR}/$@

certreq:
	openssl genrsa -out ${SECRETS_DIR}/${role}_key.pem 4096
	cp cert.conf ${role}_cert.conf
	echo "CN = ${fqdn}" >> ${role}_cert.conf
	openssl req -new -config ${role}_cert.conf -key ${SECRETS_DIR}/${role}_key.pem -out ${SECRETS_DIR}/${role}_csr.pem
	rm ${role}_cert.conf
	@tput setaf 1 0 0 && echo "Follow the steps at https://www.utdallas.edu/infosecurity/DigitalCertificates_SSL.html and put the resulting key at ${SECRETS_DIR}/${role}_cert.pem" && tput sgr0

