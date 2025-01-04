# Stratos UI pre-packager

This project is archived, see [orange-cloudfoundry/cf-stratos-ui-packager](https://github.com/orange-cloudfoundry/cf-stratos-ui-packager).

This projects helps in pre-building the
[Stratos](https://github.com/cloudfoundry-incubator/stratos) web application
so that it can be deployed faster in Cloud Foundry, or be run offline.

You can find pre-built versions of Stratos UI in the
[releases](https://github.com/orange-cloudfoundry/stratos-ui-cf-packager/releases)
of this repository.

To run those `.zip` packages inside Cloud Foundry, unzip it, write a manifest,
and `cf push` it.

You are not required to have
[stratos-buildpack](https://github.com/SUSE/stratos-buildpack), you can use
binary buildpack. Here is an example manifest that worked for us:

```yaml
applications:
  - name: console
    memory: 128M
    disk_quota: 192M
    host: console
    timeout: 180
    buildpack: binary_buildpack
    health-check-type: port
```

## Usage

Golang is required, and version 1.12 is recommended as this is the version used
by the Stratos build system.

When you want to build the `1.1.0` tag in
[Stratos UI releases](https://github.com/cloudfoundry-incubator/stratos/releases),
run this command:

```
TRAVIS_TAG=2.1.1 ./package.sh
```
