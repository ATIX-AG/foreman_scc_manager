![Rubocop](https://github.com/ATIX-AG/foreman_scc_manager/actions/workflows/rubocop.yaml/badge.svg)
![Unit Tests](https://github.com/ATIX-AG/foreman_scc_manager/actions/workflows/unit_tests.yaml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/foreman_scc_manager.svg)](https://badge.fury.io/rb/foreman_scc_manager)

# Foreman SCC Manager

Foreman plugin to sync SUSE Customer Center products and repositories into Katello.

## Installation

This plugin installation is supported since Foreman 3.4 / Katello 4.6 by the foreman-installer, but only with the scenario Katello:

```sh
foreman-install --scenario katello --enable-foreman-plugin-scc-manager
```

You can also install it manually:

```sh
yum install tfm-rubygem-foreman_scc_manager

foreman-installer
```

## Compatibility

| Foreman Version | Katello Version | Plugin Version |
| --------------- | --------------- | -------------- |
| 3.3             | 4.5             | ~> 2.0.0       |
| 3.1             | 4.3             | ~> 1.8.20\*    |
| 3.0             | 4.2             | ~> 1.8.20      |
| 2.5             | 4.1             | ~> 1.8.20      |
| 2.3             | 3.18            | ~> 1.8.9       |
| 2.1             | 3.16            | ~> 1.8.5       |
| 2.0             | 3.16            | ~> 1.8.4       |
| 1.24            | 3.14            | ~> 1.8.0       |

\* If you are using foreman_scc_manager in version 1.8.20 and then upgrade to Katello 4.3, you need to manually run the following rake task on your Foreman instance: `foreman-rake foreman_scc_manager:setup_authentication_tokens`.

## Documentation

[Plugin documentation](https://docs.orcharhino.com/or/docs/sources/guides/suse_linux_enterprise_server/managing_content/managing_suse_content.html)

## Hammer CLI Extension

[Hammer CLI for Foreman SCC Manager](https://github.com/ATIX-AG/hammer-cli-foreman-scc-manager)

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2022 ATIX AG - https://atix.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
