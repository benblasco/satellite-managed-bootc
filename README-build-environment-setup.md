# Environment setup for bootc image building and hosting

Satellite can be used to create and manage the build environment, as well as hosting build artifacts.

The process to follow is:

1. Sync the RHEL 10 bootc registry from Red Hat to Satellite
2. Create a registry within Satellite to host the built images
3. Deploy and configure a build host

Once the above is complete, then the image builds can commence, with the procedure outlined in 

## Sync the RHEL 10 bootc registry from RH

This step is not strictly mandatory if a build host has internet access to pull directly from [registry.redhat.io](registry.redhat.io), but it is good practice to control/curate content made available to hosts via Satellite.

1. Discover the RHEL 10 bootc base image repository via: Content -> Products -> Repo Discovery (button). This requires:
  - The Registry URL: `registry.redhat.io`
  - Red Hat Registry login credentials
  - Registry search parameter: `bootc`
  ![cdac2a67aa949010bed94e722c09a592.png](satellite-bootc-images/47bcc6154add4898898b69fe5ca04651.png)
2. Select the rhel10/rhel-bootc repository, and give the new repository a name e.g. `source_bootc_images`
  ![0bb2094a3cff3748b7e94b73dfc55daf.png](satellite-bootc-images/756f675d243c467f975f26ec976f9432.png)
3. Set the download policy: `On demand` (to save space), and sync the repo:
  ![ef99ad3c07d0d174cf33a21affa5b978.png](satellite-bootc-images/61d595f6ae26421dbdd153748aa31359.png)



## Create a registry within Satellite to host the built images

1. Create a custom product: Products -> Create Product
  [3.6.1. Creating a custom product by using Satellite web UI](https://docs.redhat.com/en/documentation/red_hat_satellite/6.19/html/managing_content/adding-content-to-satellite#creating-a-custom-product-by-using-web-ui)  
  Name it `bootc_images`:
  ![Create custom product](satellite-bootc-images/a025aac1bbd649b9b7eb6ec857cb4950.png)
  The newly created product will not have any repositories:
  ![Create custom product (continued)](satellite-bootc-images/1cd5b414b75b434a820c8f39a9735dcb.png)
  Create a repository called `bootc-rhel10`:
  ![Registry repository note](satellite-bootc-images/fff262e63a814695a84007e021698306.png)
  The `bootc-rhel10 repository` will now exist under the `bootc_images product`.
  ![Registry repository note (continued)](satellite-bootc-images/2d5ee69173d74d099ae47eda7e9fe671.png)
  Images in this repository will be named `satellite1.savage.test/bootc_images/bootc_rhel10`



## Deploy and configure a build host

The build host, running the latest version of the Image Builder tool (available in RHEL 10.2+ and 9.8+), is used to build the customised bootc images and push them to the registry in Satellite. 

The steps are:

1. Create a Lifecycle Environment (LCE) (path) and Content View (CV) to be used by the build host and control the content in the bootc images that will be built.
2. Deploy a build host within that LCE
3. Install the tools required for the build
4. ~~Build the customised bootc image via your Containerfile~~
5. ~~Push the image to the registry in Satellite~~



## Create a Lifecycle Environment (LCE) (path) and Content View (CV) for the build host

Note: This section is very brief as it is following normal procedures for managing package mode hosts in Satellite.

1. Create a LCE for the build environment. It is only necessary to create a single build environment unless historical builds need to be reproduced for some reason (I can't think of). The example below is using the existing SOE10 `Development` environment. The `Qualification` and `Production` environments are redundant in this context.  
  ![Build host LCE.png](satellite-bootc-images/build_host_lce.png)
