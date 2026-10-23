# Satellite bootc (image mode) provisioning

Internal guide for provisioning **RHEL image mode (bootc)** VMs with **Red Hat Satellite**, **Anaconda kickstart**, and a **libvirt** compute resource (hypervisor) configured in **Satellite**.

Most of the background and concept came from Ian Ballou's great article: [Provisioning image mode for RHEL using Satellite](https://developers.redhat.com/articles/2026/08/06/image-mode-for-rhel-with-anaconda-and-satellite).  
  
## Test environment details


### Lab placeholders (replace for your environment)

| Placeholder                 | This guide uses                 | Where it appears                                                       |
| --------------------------- | ------------------------------- | ---------------------------------------------------------------------- |
| Satellite FQDN              | `satellite1.savage.test`        | Registry URLs, kickstart, CA download                                  |
| Organization label          | `default_organization`          | Container image paths (`.../default_organization/...`)                 |
| DNS domain                  | `savage.test`                   | Host FQDNs, provisioning network                                       |
| Libvirt compute resource    | `nuc`                           | Host group, VNC on `nuc.lan`                                           |
| Build-host lifecycle (SOE)  | SOE10 `Development`             | [README-build-environment-setup.md](README-build-environment-setup.md) |
| Deploy lifecycle / CV       | `bootc_dev` / `bootc_rhel10`    | Host group, `inst.stage2`, activation key                              |
| Activation key              | `bootc_rhel10_dev`              | Host group parameter `kt_activation_keys`                              |
| Host group                  | `hg_x86_64_bootc_rhel10_vm`     | Provisioning entry point                                               |
| Upstream bootc mirror repo  | `source_bootc_images`           | Containerfile `FROM` (Satellite registry)                              |
| Custom image product / repo | `bootc_images` / `bootc_rhel10` | Build push target, deploy CV                                           |

### Container registry paths

Container registry paths use your Satellite **organization label** (here `default_organization` in `satellite1.savage.test/default_organization/...`). Find it under **Administer → Organizations →** *your org* **→ Label**.

## Documentation (run in order)

1. [README-build-environment-setup.md](README-build-environment-setup.md) — Prepare Satellite (sync upstream bootc content, custom registry product/repo) and deploy a build host with the right lifecycle environment and content view.
2. [README-build-image.md](README-build-image.md) — On the build host, construct and push a customised bootc container image to Satellite's registry.
3. [README-deploy-host.md](README-deploy-host.md) — Publish bootc image content for provisioning, configure host groups and kickstart templates, and network-provision bootc VMs.