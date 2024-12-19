[![Ruby Tests](https://github.com/ATIX-AG/foreman_scc_manager/actions/workflows/ruby_tests.yml/badge.svg)](https://github.com/ATIX-AG/foreman_scc_manager/actions/workflows/ruby_tests.yml)
[![Gem Version](https://badge.fury.io/rb/foreman_scc_manager.svg)](https://badge.fury.io/rb/foreman_scc_manager)

# Foreman SCC Manager

Foreman plugin to sync SUSE Customer Center products and repositories into Katello.

## Installation

This plugin installation is supported since Foreman 3.4 / Katello 4.6 by the foreman-installer, but only with the scenario Katello:

```sh
foreman-installer --scenario katello --enable-foreman-plugin-scc-manager
```

You can also install it manually:

```sh
dnf install rubygem-foreman_scc_manager

foreman-installer
```

## Compatibility

| Foreman Version | Katello Version | Plugin Version |
| --------------- | --------------- | -------------- |
| 3.13            | 4.15            | ~> 4.0.0       |
| 3.7             | 4.9             | ~> 3.0.0       |
| 3.3             | 4.5             | ~> 2.0.0       |
| 3.1             | 4.3             | ~> 1.8.20\*    |
| 3.0             | 4.2             | ~> 1.8.20      |

\* If you are using foreman_scc_manager in version 1.8.20 and then upgrade to Katello 4.3, you need to manually run the following rake task on your Foreman instance: `foreman-rake foreman_scc_manager:setup_authentication_tokens`.

## Documentation

[Plugin documentation](https://docs.theforeman.org/nightly/Managing_Content/index-katello.html#Managing_SUSE_Content_content-management)

## Hammer CLI Extension

[Hammer CLI for Foreman SCC Manager](https://github.com/ATIX-AG/hammer-cli-foreman-scc-manager)

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2024 ATIX AG - https://atix.de

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
