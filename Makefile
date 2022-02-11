# Copyright 2022 VMware. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

REQUIRED_BINARIES := imgpkg kbld ytt
CORE_OCI_IMAGE := ghcr.io/alexandreroman/tce-local-core
MONITORING_OCI_IMAGE := ghcr.io/alexandreroman/tce-local-monitoring
KNATIVE_OCI_IMAGE := ghcr.io/alexandreroman/tce-local-knative
REPO_OCI_IMAGE := ghcr.io/alexandreroman/tce-local

check-carvel:
	$(foreach exec,$(REQUIRED_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. Carvel toolset is required. See instructions at https://carvel.dev/#install")))

clean:
	rm -rf repo pkg/core/.imgpkg pkg/monitoring/.imgpkg pkg/knative/.imgpkg

push: check-carvel # Build and push packages.
	rm -rf pkg/core/.imgpkg && mkdir pkg/core/.imgpkg && kbld -f pkg/core/config --imgpkg-lock-output pkg/core/.imgpkg/images.yml && \
	rm -rf pkg/monitoring/.imgpkg && mkdir pkg/monitoring/.imgpkg && kbld -f pkg/monitoring/config --imgpkg-lock-output pkg/monitoring/.imgpkg/images.yml && \
	rm -rf pkg/knative/.imgpkg && mkdir pkg/knative/.imgpkg && kbld -f pkg/knative/config --imgpkg-lock-output pkg/knative/.imgpkg/images.yml && \
	mkdir -p repo/packages && \
	ytt -f pkg/core/metadata.yaml -f pkg/core/package.yaml > repo/packages/core.yaml && \
	ytt -f pkg/monitoring/metadata.yaml -f pkg/monitoring/package.yaml > repo/packages/monitoring.yaml && \
	ytt -f pkg/knative/metadata.yaml -f pkg/knative/package.yaml > repo/packages/knative.yaml && \
	imgpkg push --bundle $(CORE_OCI_IMAGE) --file pkg/core && \
	imgpkg push --bundle $(MONITORING_OCI_IMAGE) --file pkg/monitoring && \
	imgpkg push --bundle $(KNATIVE_OCI_IMAGE) --file pkg/knative && \
	rm -rf repo/.imgpkg && mkdir -p repo/.imgpkg && \
	kbld -f repo/packages --imgpkg-lock-output repo/.imgpkg/images.yml && \
	imgpkg push --bundle $(REPO_OCI_IMAGE) --file repo

cluster-create:
	tanzu unmanaged-cluster create tce-local -c calico -p 80:80 -p 443:443

repo-add:
	tanzu package repository add tce-local --url $(REPO_OCI_IMAGE) -n tanzu-package-repo-global

install-core:
	tanzu package install local-core --package-name core.local.community.tanzu.vmware.com --version 1.0.0

install-monitoring:
	tanzu package install local-monitoring --package-name monitoring.local.community.tanzu.vmware.com --version 1.0.0

install-knative:
	tanzu package install local-knative --package-name knative.local.community.tanzu.vmware.com --version 1.0.0
