#!/usr/bin/env bash
set -e

# Build and statically link acserver (this requires it to already be downloaded)
echo "Building acserver..."
CGO_ENABLED=0 GOOS=linux go build -o acserver -a -tags netgo -ldflags '-w' github.com/appc/acserver

rmAcserver() { rm acserver; }
acbuildEnd() {
    rmAcserver
    export EXIT=$?
    acbuild --debug end && exit $EXIT
}

# When the script exits, remove the binary we built
trap rmAcserver EXIT

# Start the build with an empty ACI
acbuild --debug begin

# In the event of the script exiting, end the build
trap acbuildEnd EXIT

# Name the ACI
acbuild --debug set-name example.com/acserver

# Copy the binary and its templates into the ACI
acbuild --debug copy acserver /bin/acserver
acbuild --debug copy $GOPATH/src/github.com/appc/acserver/templates /templates

# Add a mount point for the ACIs to serve
acbuild --debug mount add acis /acis

# Run acserver
acbuild --debug set-exec -- /bin/acserver -port 80 localhost /acis /templates user passwd

# Save the resulting ACI
acbuild --debug write --overwrite acserver-latest-linux-amd64.aci
