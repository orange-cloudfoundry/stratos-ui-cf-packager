# stratos-ui-cf-packager

Package a [stratos-ui](https://github.com/SUSE/stratos-ui) build to make it runnable offline.

This will be always packaged for linux as SUSE team use [golang plugin](https://golang.org/doc/go1.8#plugin) 
build mode which is only available on linux (OSX doesn't work too).

You can find packaged version of stratos-ui in https://github.com/orange-cloudfoundry/stratos-ui-cf-packager/releases .

To run it inside your cloud foundry, you are not required to have [stratos-buildpack](https://github.com/SUSE/stratos-buildpack), you can use binary buildpack.
