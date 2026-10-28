# Build the customised bootc container image

Once the [environment setup](README-build-environment-setup.md) is complete (including container tools, Satellite CA trust, and `containers-auth.json` on the build host), image builds can take place.

All actions below take place on the **build host**.

---

## Build context files

Before building, gather these files in the directory that contains your Containerfile:

| File | Purpose |
| ---- | ------- |
| `katello-server-ca.crt` | Satellite CA copied into the image (e.g. `curl -o katello-server-ca.crt http://satellite1.savage.test/pub/katello-server-ca.crt`) |
| `containers-auth.json` | Registry credentials baked into the image at `/etc/ostree/auth.json` (created during [environment setup](README-build-environment-setup.md)) |
| `id_rsa.pub` | SSH public key for root login in the image |
| `redhat.repo` (or equivalent) | Yum/DNF repo definitions used inside the image build (your Satellite subscription layout) |

---

## Create a Containerfile

The bootc base image tag should be **older** than the RPM content snapshot in the build host's content view (for example, choose a `source_bootc_images` tag from before your CV date filter, sync that repo, then build after the CV is promoted).

Example Containerfile:

```dockerfile
FROM satellite1.savage.test/default_organization/source_bootc_images/rhel10_rhel-bootc:10.2-1791784396
#FROM registry.redhat.io/rhel10/rhel-bootc:1784790803

###############################################
# From Waldirio Pinheiro video
#  Setting Up Bootc with Red Hat Satellite: A Guide to Bootable Container Images
# https://www.youtube.com/watch?v=7d8DqlDuwJU

# Satellite certificate so that bootc instances can trust Satellite
# Retrieve the certificate via:
# curl -o katello-server-ca.crt http://satellite1.savage.test/pub/katello-server-ca.crt
# or
# wget http://satellite1.savage.test/pub/katello-server-ca.crt
COPY katello-server-ca.crt /etc/pki/ca-trust/source/anchors
RUN update-ca-trust

# This is the credential to authenticate to Satellite's registry (assuming it is a closed registry)
# Waldirio says the documentation on this is poor and he filed some docs issues. Not sure if fixed yet
# Retrieve the auth file via:
# cp ${XDG_RUNTIME_DIR}/containers/auth.json containers-auth.json
# or
# podman login satellite1.savage.test --authfile containers-auth.json
COPY containers-auth.json /etc/ostree/auth.json

###############################################
# Make sure we use the right Satellite repos
# Optional: Remove default repos if replacing them entirely
RUN rm -f /etc/yum.repos.d/*.repo

# Copy your custom repo file into the container
#COPY etc/yum.repos.d/redhat.repo /etc/yum.repos.d/redhat.repo
#COPY etc/yum.repos.d/redhat.repo /run/secrets/redhat.repo
#RUN grep savage /etc/yum.repos.d/redhat.repo
RUN cat /run/secrets/redhat.repo

RUN <<EOF
    set -euo pipefail
        dnf install -y httpd firewalld openssh-server bash-completion tmux rhc-worker-playbook
        #dnf install -y httpd openssh-server bash-completion tmux rhc-worker-playbook
        dnf update -y --exclude="kernel*" --setopt="install_weak_deps=false"
        dnf clean all
EOF

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

RUN systemctl enable httpd
#RUN systemctl enable firewalld

# Set the timezone
RUN ln -s /usr/share/zoneinfo/Australia/Melbourne /etc/localtime

# Lint the container image
RUN bootc container lint
```

## Build the container image

```bash
podman build -t satellite1.savage.test/default_organization/bootc_images/bootc_rhel10:20261019 .
```

## Push to the container registry

[14.3.4. Pushing container images to Satellite](https://docs.redhat.com/en/documentation/red_hat_satellite/6.19/html/managing_content/managing_container_images_content-management#pushing-container-images-to-satellite)

Build and push use Satellite’s **Library push path**: `<fqdn>/<org_label>/<product_label>/<repo_label>:<tag>` (here `default_organization/bootc_images/bootc_rhel10`). That lands the image in the library repository. **Hosts and provisioning do not pull from this path** once the image is in a content view—after publish and promote they use a **CV/LCE-specific** registry path (see [README-deploy-host.md](README-deploy-host.md)). Copy the exact pull path from **Content → Container image tags** (pullable paths) for your target lifecycle environment.

```bash
# podman push My_Container_Image_ID satellite.example.com/My_Organization_Label/My_Product_Label/My_Repository_Name[:My_Tag]
podman push satellite1.savage.test/default_organization/bootc_images/bootc_rhel10:20261019 .
```

After push, follow [Publish and promote container images via image tags](README-deploy-host.md#publish-and-promote-container-images-via-image-tags) in the deploy guide before provisioning VMs with the new tag.

## Verify the image in Satellite

Products -> bootc_images (product) -> bootc_rhel10 (repository) -> Container image manifests

![Container image manifests/tags](satellite-bootc-images/container_image_manifests.png)
