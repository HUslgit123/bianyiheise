TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := GameModMenu

GameModMenu_FILES := Tweak.x
GameModMenu_CFLAGS := -fobjc-arc -Wno-unused-variable -Wno-unused-function
GameModMenu_FRAMEWORKS := UIKit Foundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
