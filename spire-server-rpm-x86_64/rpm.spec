Name:           spire-server
Version:        %{version}
Release:        1%{?dist}
Summary:        Server components for SPIRE
License:        MIT
URL:            https://github.com/spiffe/spire
Source0:        https://github.com/spiffe/spire/archive/v%{version}.tar.gz

Requires:       systemd

%description
Server for SPIRE. 

# Turn off debug builds for this package -- they would need makefile changes
%global debug_package %{nil}
%define _build_id_links none
%prep

%setup -q -n spire-%{version}

%build
export GOFLAGS='-ldflags=-extldflags=-static'
make

%install
rm -rf %{buildroot}

install -D -m 0755 %{_builddir}/spire-%{version}/bin/spire-server %{buildroot}%{_bindir}/spire-server
install -D -m 0755 %{_builddir}/spire-%{version}/bin/spire-server %{buildroot}%{_bindir}/spire-oidc-discovery-provider
install -D -m 0644 %{_builddir}/spire-%{version}/conf/server/dummy_upstream_ca.crt %{buildroot}%{_sysconfdir}/spire/server/dummy_upstream_ca.crt.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/server/server.conf %{buildroot}%{_sysconfdir}/spire/server/server.conf.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/server/dummy_upstream_ca.key %{buildroot}%{_sysconfdir}/spire/server/dummy_upstream_ca.key.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/server/server_container.conf %{buildroot}%{_sysconfdir}/spire/server/server_container.conf.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/server/server_full.conf %{buildroot}%{_sysconfdir}/spire/server/server_full.conf.example

# spire-server.service comes from the spire-packages repo, not the main repo
install -D -m 0644 %(pwd)/spire-server.service %{buildroot}/usr/lib/systemd/system/spire-server.service

%pre
# Check if the user exists before trying to create it
if ! getent passwd spire-server > /dev/null 2>&1; then
    /usr/sbin/useradd --system --no-create-home --user-group spire-server > /dev/null 2>&1 || :
fi

%post
%systemd_post spire-server.service

%preun
%systemd_preun spire-server.service
if [ $1 -eq 0 ]; then
    /usr/sbin/userdel spire-server > /dev/null 2>&1 || :
fi

%postun
%systemd_postun_with_restart spire-server.service

%files
%{_bindir}/spire-server
%{_bindir}/spire-oidc-discovery-provider
%{_sysconfdir}/spire/server/dummy_upstream_ca.crt.example
%{_sysconfdir}/spire/server/server.conf.example
%{_sysconfdir}/spire/server/dummy_upstream_ca.key.example
%{_sysconfdir}/spire/server/server_container.conf.example
%{_sysconfdir}/spire/server/server_full.conf.example
/usr/lib/systemd/system/spire-server.service

# Warning: if the changelog is incorrectly formatted, it will fail to build on some platforms.
%changelog
* Tue May 02 2024 Daniel Feldman <dfeldman.mn@gmail.com> - 1.9.0-1
- Initial release of the package.
