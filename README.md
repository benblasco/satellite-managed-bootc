# Satellite bootc (image mode) provisioning

Internal runbook for provisioning **RHEL image mode (bootc)** VMs with **Red Hat Satellite** (`satellite1.savage.test`), **Anaconda kickstart**, and the **nuc** libvirt compute resource on `savage.test`.

Most of the background and concept came from Ian Ballou's great article: [Provisioning image mode for RHEL using Satellite](https://developers.redhat.com/articles/2026/08/06/image-mode-for-rhel-with-anaconda-and-satellite).

## Documentation (run in order)

1. [README-build-environment-setup.md](README-build-environment-setup.md) — Prepare Satellite (sync upstream bootc content, custom registry product/repo) and deploy a build host with the right lifecycle environment and content view.
2. [README-build-image.md](README-build-image.md) — On the build host, construct and push a customized bootc container image to Satellite's registry.
3. [README-deploy-host.md](README-deploy-host.md) — Publish bootc image content for provisioning, configure host groups and kickstart templates, and network-provision bootc VMs.
