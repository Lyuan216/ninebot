ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

# rootless 越狱 (Dopamine / palera1n rootless / 无根环境必须加这行)
# 若目标是传统 rootful 越狱，把下面这行注释掉
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = Segway-Ninebot

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LabelPatch
LabelPatch_FILES = Tweak.x
LabelPatch_CFLAGS = -fobjc-arc
LabelPatch_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Segway-Ninebot || true"
