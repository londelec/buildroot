################################################################################
#
# cron
#
################################################################################

CRON_VERSION = 3.0pl1
CRON_SOURCE = cron_$(CRON_VERSION).orig.tar.gz
CRON_SITE = https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/cron/$(CRON_VERSION)-151ubuntu1
CRON_EXTRA_DOWNLOADS = cron_$(CRON_VERSION)-151ubuntu1.debian.tar.xz
CRON_LICENSE = GPL-2.0+

# Extract the Debian tarball inside the sources
define CRON_DEBIAN_EXTRACT
	$(call suitable-extractor,$(notdir $(CRON_EXTRA_DOWNLOADS))) \
		$(CRON_DL_DIR)/$(notdir $(CRON_EXTRA_DOWNLOADS)) | \
		$(TAR) -C $(@D) $(TAR_OPTIONS) -
endef

CRON_POST_EXTRACT_HOOKS += CRON_DEBIAN_EXTRACT

define CRON_DEBIAN_PATCH
	$(APPLY_PATCHES) $(@D) $(@D)/debian/patches \*
endef

CRON_PRE_PATCH_HOOKS += CRON_DEBIAN_PATCH

define CRON_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" -C $(@D)
endef

define CRON_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m0755 $(@D)/cron $(TARGET_DIR)/usr/sbin/cron
	$(INSTALL) -D -m4755 $(@D)/crontab $(TARGET_DIR)/usr/bin/crontab
endef

define CRON_DEBIAN_INSTALL_ADDITIONAL
	$(INSTALL) -D -m0644 $(@D)/debian/crontab.main $(TARGET_DIR)/etc/crontab
	$(INSTALL) -d -m0755 \
		$(TARGET_DIR)/etc/cron.daily $(TARGET_DIR)/etc/cron.hourly \
		$(TARGET_DIR)/etc/cron.monthly $(TARGET_DIR)/etc/cron.weekly
endef

#CRON_POST_INSTALL_TARGET_HOOKS += CRON_DEBIAN_INSTALL_ADDITIONAL

$(eval $(generic-package))
