Name:       c-b20-505-12
Version:    1.0
Release:    1%{?dist}
Summary:    Программа студента М. Тимофея группы Б20-505
Group:      Testing
License:    GPL
URL:        https://github.com/ne-bknn/ossec_labs
Source:     %{name}-%{version}.tar.gz
BuildRequires: gcc

%description
A test package

%prep
%setup -q

%build
gcc -O2 -o c-b20-505-12 c-b20-505-12.c

%install
mkdir -p %{buildroot}%{_bindir}
cp c-b20-505-12 %{buildroot}%{_bindir}
sudo rpm -i ~/rpmbuild/RPMS/noarch/b20-505-12-1.0-1.el8.noarch.rpm --force

%files
%{_bindir}/c-b20-505-12

%changelog
* Fri Jun 02 2023 Мищенко
- Added %{_bindir}/c-b20-505-12
