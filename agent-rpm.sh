Name:           spire-agent
Version:        %{version}
Release:        1%{?dist}
Summary:        Client agent for SPIRE
License:        MIT
URL:            https://github.com/spiffe/spire
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.20
Requires:       systemd

%description
Agent for SPIRE, which authenticates and delivers certificates to workloads using a workload API UDS socket

%prep
%setup -q

%build
./scripts/build.sh

%install
rm -rf %{buildroot}
install -D -m 0755 bin/binary1 %{buildroot}%{_bindir}/binary1
install -D -m 0755 bin/binary2 %{buildroot}%{_bindir}/binary2
install -D -m 0755 bin/daemon %{buildroot}%{_bindir}/myproject-daemon
install -D -m 0644 config/config1.yaml %{buildroot}%{_sysconfdir}/myproject/config1.yaml
install -D -m 0644 config/config2.yaml %{buildroot}%{_sysconfdir}/myproject/config2.yaml
install -D -m 0644 systemd/myproject-daemon.service %{buildroot}%{_unitdir}/myproject-daemon.service

%post
%systemd_post myproject-daemon.service

%preun
%systemd_preun myproject-daemon.service

%postun
%systemd_postun_with_restart myproject-daemon.service

%files
%{_bindir}/binary1
%{_bindir}/binary2
%{_bindir}/myproject-daemon
%{_sysconfdir}/myproject/config1.yaml
%{_sysconfdir}/myproject/config2.yaml
%{_unitdir}/myproject-daemon.service

%changelog
* Sun May 30 2023 Your Name <you@example.com> - 1.0.0-1
- Initial package