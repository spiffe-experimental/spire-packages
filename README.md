# spire-packages

This repo contains GitHub Actions workflows to create RPM and DEB packages for spire-server and spire-agent. 

The binaries in these packages are statically linked, so they should work on any distribution. The workflow tests a few 
common distributions in containers to double-check. 

The current distributions tested are: Ubuntu, Debian, Amazon Linux, Red Hat UBI, Fedora, CentOS, OpenSuSE LEAP. 
All are tested with the latest container release at the time of testing. 

The workflow runs nightly. If there's a new tag in the official SPIRE repo, it builds the corresponding packages. 
This means it may take a day after release before packages are ready. The test script verifies that all files
are created and that the binaries actually run, but don't test any functionality. (The assumption is that any 
tagged SPIRE release has already passed all the functional tests.)

The packages also install a systemd unit to run spire-agent and spire-server, and corresponding user accounts. 
The systemd unit is disabled by default (since the user has to do manual configuration in any case). 

The workflow also produces .src.rpm packages, which allow downstream consumers to rebuild the binaries 
(for reproducibility).

This is still work in progress. Please do not rely on it.

## Does it make sense to have a server package?

In production use, spire-server should ALWAYS be HA, which is difficult to set up using individual VMs/
containers. You should almost always use the official Helm chart on a Kubernetes cluster which makes this easy.

However, the server packages make sense for developers, and for deployment inside other platforms that support 
HA (like EC2 with load balancers).

Also it would be confusing to only produce agent packages. 

## Should there be an extras package?

SPIRE on its own is not much use on a standalone machine. You would typically need Envoy, OPA, and some 
kind of node attestor that works on standalone machines. It makes sense to have additional packages that contain
these so they can be installed very easily. It should also include typical configuration examples or even
a config helper script. This isn't done yet though.

## Should there be a Tornjak package?

There probably should be. Unlike SPIRE itself, Tornjak doesn't have to be HA, so it can run on a standalone
machine easily. Configuration for Tornjak to talk to SPIRE is a bit complicated in this configuration though.

## Why not use npfm or alien?

It would be simpler to auto-build cross-platform packages using npfm or alien. However, those tools
do not support source packages at all, which would preclude adoption into distribution repos.

## To do: 
 * Verify packages really work for real users
 * Build for Linux ARM64 (requires an external runner)
 * Build Debian source packages as well (.dsc file)
 * Sign packages 
 * Enable GitHub Artifact Attestation
 * Create Debian package repository for continual updates
 * Add config file examples that make sense for typical bare-metal users
 * Add spire-agent-extras and spire-server-extras packages with useful additions like more plugins, Envoy and OPA support
 * Other package formats: apk, Mandriva, Homebrew, Chocolatey, Nix, Flatpak, AppImage?
 * Eventually, upstream into mainline SPIFFE org
 * Eventually, propose these for inclusion into major distribution package repos

## WARNING: EXPERIMENTAL
These packages are not yet ready for production use. 

This is NOT an official SPIFFE/CNCF project. Hopefully when we have more experience it can be adopted officially into the SPIFFE org. 

