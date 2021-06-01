ifeq ($(PACKAGE_SET),dom0)
RPM_SPEC_FILES := qubes-windows-tools.spec
NO_ARCHIVE := 1

USE_DIST_BUILD_TOOLS = 1

INCLUDED_SOURCES = \
  qubes-core-vchan-xen \
  qubes-core-agent-windows \
  qubes-core-qubesdb \
  qubes-windows-utils \
  qubes-gui-common \
  qubes-gui-agent-windows \
  qubes-installer-qubes-os-windows-tools \
  qubes-vmm-xen-windows-pvdrivers \
  qubes-vmm-xen-win-pvdrivers-xeniface \

SOURCE_COPY_IN := $(INCLUDED_SOURCES)

$(INCLUDED_SOURCES): SRC_SUBDIR=$@
$(INCLUDED_SOURCES): VERSION=$(shell git -C $(ORIG_SRC)/$(SRC_SUBDIR) rev-parse --short HEAD)
$(INCLUDED_SOURCES):
	$(BUILDER_DIR)/scripts/create-archive $(CHROOT_DIR)/$(DIST_SRC)/$(SRC_SUBDIR) $(SRC_SUBDIR)-$(VERSION).tar.gz $(SRC_SUBDIR)/
	mv $(CHROOT_DIR)/$(DIST_SRC)/$(SRC_SUBDIR)/$(SRC_SUBDIR)-$(VERSION).tar.gz $(CHROOT_DIR)/$(DIST_SRC)
	sed -i "s#@$(SRC_SUBDIR)@#$(SRC_SUBDIR)-$(VERSION).tar.gz#" $(CHROOT_DIR)/$(DIST_SRC)/qubes-windows-tools.spec.in
endif
