################################################################################
#
# less
#
################################################################################

LESS_VERSION = 590
LESS_SITE = http://www.greenwoodsoftware.com/less
LESS_LICENSE = GPL-3.0+
LESS_LICENSE_FILES = COPYING
LESS_CPE_ID_VENDOR = gnu
LESS_DEPENDENCIES = ncurses

define LESS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/less $(TARGET_DIR)/usr/bin/less
	$(INSTALL) -m 0755 $(@D)/lessecho $(TARGET_DIR)/usr/bin/lessecho
	$(INSTALL) -m 0755 $(@D)/lesskey $(TARGET_DIR)/usr/bin/lesskey
endef

$(eval $(autotools-package))
