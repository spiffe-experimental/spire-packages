Name:           spire-agent
Version:        %{version}
Release:        1%{?dist}
Summary:        Client agent for SPIRE
License:        MIT
URL:            https://github.com/spiffe/spire
Source0:        https://github.com/spiffe/spire/archive/v%{version}.tar.gz

Requires:       systemd

%description
Agent for SPIRE, which authenticates and delivers certificates to workloads using a workload API UDS socket

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

install -D -m 0755 %{_builddir}/spire-%{version}/bin/spire-agent %{buildroot}%{_bindir}/spire-agent
install -D -m 0644 %{_builddir}/spire-%{version}/conf/agent/agent_full.conf %{buildroot}%{_sysconfdir}/spire/agent/agent_full.conf.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/agent/agent.conf %{buildroot}%{_sysconfdir}/spire/agent/agent.conf.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/agent/agent_container.conf %{buildroot}%{_sysconfdir}/spire/agent/agent_container.conf.example
install -D -m 0644 %{_builddir}/spire-%{version}/conf/agent/dummy_root_ca.crt %{buildroot}%{_sysconfdir}/spire/agent/dummy_root_ca.crt

# spire-agent.service comes from the spire-packages repo, not the main repo
install -D -m 0644 %(pwd)/spire-agent.service %{buildroot}/usr/lib/systemd/system/spire-agent.service

%pre
# Check if the user exists before trying to create it
if ! getent passwd spire-agent > /dev/null 2>&1; then
    /usr/sbin/useradd --system --no-create-home --user-group spire-agent > /dev/null 2>&1 || :
fi

%post
%systemd_post spire-agent.service

%preun
%systemd_preun spire-agent.service
if [ $1 -eq 0 ]; then
    /usr/sbin/userdel spire-agent > /dev/null 2>&1 || :
fi

%postun
%systemd_postun_with_restart spire-agent.service

%files
%{_bindir}/spire-agent
%{_sysconfdir}/spire/agent/agent_full.conf.example
%{_sysconfdir}/spire/agent/agent.conf.example
%{_sysconfdir}/spire/agent/agent_container.conf.example
%{_sysconfdir}/spire/agent/dummy_root_ca.crt
/usr/lib/systemd/system/spire-agent.service

%changelog
* Tue May 02 2024 Daniel Feldman <dfeldman.mn@gmail.com> - 1.9.0-1
- Initial release of the package.