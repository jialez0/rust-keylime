Name:           keylime-agent
Version:        0.2.8
Release:        1%{?dist}
Summary:        Rust Keylime Compute Agent

License:        Apache-2.0
URL:            https://github.com/keylime/rust-keylime
Source0:        rust-keylime-%{version}.tar.gz

# Disable automatic debuginfo/debugsource subpackages to avoid empty debugsourcefiles.list
%global _enable_debug_packages 0
%global debug_package %{nil}

# Build dependencies
# BuildRequires:  cargo
# BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  openssl-devel
BuildRequires:  pkgconfig(openssl)
# BuildRequires:  pkgconfig(systemd)
# BuildRequires:  systemd

# Runtime for systemd units handling
%{?systemd_requires}
Requires(post):   systemd
Requires(preun):  systemd
Requires(postun): systemd

%description
Keylime is a remote attestation and integrity monitoring framework. This
package provides the Rust implementation of the Keylime compute agent,
which can be managed via systemd.

%prep
%autosetup -n rust-keylime-%{version}

%build
make RELEASE=1

%install
# Install only keylime_agent, the required unit, and the config
install -D -m 0755 target/release/keylime_agent \
  %{buildroot}%{_bindir}/keylime_agent

install -D -m 0644 keylime-agent.conf \
  %{buildroot}%{_sysconfdir}/keylime/agent.conf

install -D -m 0644 dist/systemd/system/keylime_agent.service \
  %{buildroot}%{_unitdir}/keylime_agent.service
install -D -m 0644 dist/systemd/system/var-lib-keylime-secure.mount \
  %{buildroot}%{_unitdir}/var-lib-keylime-secure.mount

%post
%systemd_post keylime_agent.service var-lib-keylime-secure.mount

%preun
%systemd_preun keylime_agent.service var-lib-keylime-secure.mount

%postun
# Reload/restart units as needed after upgrade/removal
%systemd_postun_with_restart keylime_agent.service

%files
%license LICENSE
%doc README.md
%dir %{_sysconfdir}/keylime
%config(noreplace) %{_sysconfdir}/keylime/agent.conf
%{_bindir}/keylime_agent
%{_unitdir}/keylime_agent.service
%{_unitdir}/var-lib-keylime-secure.mount

%changelog
* Thu Oct 30 2025 Packager <packager@example.com> - 0.2.8-1
- Initial packaging: build Rust keylime_agent, install systemd units and config.


