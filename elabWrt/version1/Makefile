#
# Copyright (C) 2026 elab <elab@example.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-experiment
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=elab <SuwakoDragon@github.com>
PKG_LICENSE:=Apache-2.0

LUCI_TITLE:=LuCI app for network experiments
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-compat

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-experiment/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || {
	chmod +x /usr/bin/inject_experiment_fault.sh
	chmod +x /usr/bin/repair_experiment_field.sh
	chmod +x /usr/bin/reset_experiment.sh
}
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,luci-app-experiment))
