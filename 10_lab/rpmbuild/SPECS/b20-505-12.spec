Name:          b20-505-12
Version:       1.0
Release:       1%{?dist}
Summary:       Программа студента М. Тимофея группы Б20-505
Group:         Testing
License:       GPL
URL:           https://github.com/ne-bknn/ossec_labs
Source0:       %{name}-%{version}.tar.gz
BuildRequires: /bin/rm, /bin/mkdir, /bin/cp
Requires:      /bin/bash, /usr/bin/date, gnuplot
BuildArch:     noarch

%description
A test package

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 b20-505-12 %{buildroot}%{_bindir}

%files
%{_bindir}/b20-505-12

%changelog
* Fri Jun 2 2023 Мищенко
- Added %{_bindir}/b20-505-12
