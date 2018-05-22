# Stratos UI pre-packager

This projects helps in pre-building the
[Stratos](https://github.com/cloudfoundry-incubator/stratos) web application
so that it can be deployed faster in Cloud Foundry, or be run offline.

There is no support for any other target system than Linux. Indeed, the
Stratos plugin system uses Go
[`plugin` build mode](https://golang.org/doc/go1.8#plugin) which is only
available for Linux in Go versions 1.8 and 1.9. As of
[Go 1.10](https://golang.org/doc/go1.10) though, the `plugin` build mode has
been ported to macOS (`darwin/amd64`). But this has not been tested yet. You
feedback is welcome here.

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

Golang is required, and version 1.9 is recommended as this is the cersion used
by the Stratos build system.

When you want to build the `1.1.0` tag in
[Stratos UI releases](https://github.com/cloudfoundry-incubator/stratos/releases),
run this command:

```
TRAVIS_TAG=1.1.0 ./package.sh
```
