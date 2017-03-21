# This package contains macros that provide functionality relating to
# Software Collections. These macros are not used in default
# Fedora builds, and should not be blindly copied or enabled.
# Specifically, the "scl" macro must not be defined in official Fedora
# builds. For more information, see:
# http://docs.fedoraproject.org/en-US/Fedora_Contributor_Documentation
# /1/html/Software_Collections_Guide/index.html

%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global scl_ruby ror42
%global scl_prefix_ruby sclo-ror42-

%global gem_name foreman_scc_manager

%global foreman_dir /usr/share/foreman
%global foreman_bundlerd_dir %{foreman_dir}/bundler.d

Summary:    Suse Customer Center plugin for foreman
Name:       %{gem_name}
Version:    1.0.0
Release:    1%{?dist}
Group:      Applications/System
License:    GPLv3
URL:        http://orcharhino.com
Source0:    %{gem_name}.tar.gz
Packager:   ATIX AG <info@atix.de>

# Global requirements
#####################
# foreman
Requires: foreman >= 1.13
# katello
Requires: katello >= 3.2.0

BuildArch: noarch

Provides: %{?scl_prefix}rubygem(%{gem_name}) = %{version}
Provides: foreman_scc_manager                = %{version}

%description
Suse Customer Center plugin for foreman

%package doc
BuildArch:  noarch
Requires:   %{?scl_prefix}%{pkg_name} = %{version}-%{release}
Summary:    Documentation for rubygem-%{gem_name}

%description doc
This package contains documentation for %{gem_name}.

%prep
# %setup -n %{pkg_name}-%{version} -q -c -T
%setup -q -c

%build
%{?scl:scl enable %{scl} "}
gem build %{gem_name}.gemspec
%{?scl:"}

%install
rm -rf ${buildroot}

install -m 755 -d %{buildroot}%{gem_dir}
%{?scl:scl enable %{scl} "}
gem install --local --install-dir %{buildroot}%{gem_dir} \
            --force %{gem_name}-%{version}.gem --no-rdoc --no-ri
%{?scl:"}

mkdir -p %{buildroot}%{foreman_bundlerd_dir}
cat <<GEMFILE > %{buildroot}%{foreman_bundlerd_dir}/%{gem_name}.rb
gem '%{gem_name}'
GEMFILE

# Install other stuff extra to the gem
install -m 755 -d %{buildroot}%{_bindir}

%posttrans
scl enable tfm "cd /usr/share/foreman && rake db:migrate && rake plugin:assets:precompile['%{gem_name}']" >/dev/null 2>&1
(/bin/katello-service status && /bin/katello-service restart) >/dev/null 2>&1

exit 0

%files
%dir %{gem_instdir}
%{gem_instdir}/*
%{foreman_bundlerd_dir}/%{gem_name}.rb
%{gem_spec}

%exclude %{gem_instdir}/test
%exclude %{gem_cache}

%files doc
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/README.md

%changelog
* Tue Mar 21 2017 Matthias Dellweg <dellweg@atix.de> 1.0.0-1
- First release
