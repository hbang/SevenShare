include theos/makefiles/common.mk

BUNDLE_NAME = SevenShare
SevenShare_FILES = $(wildcard *.m) $(wildcard *.x)
SevenShare_FRAMEWORKS = UIKit CoreGraphics MessageUI MobileCoreServices Social
SevenShare_PRIVATE_FRAMEWORKS = PhotoLibraryServices SpringBoardUIServices
SevenShare_INSTALL_PATH = /System/Library/WeeAppPlugins

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec spring
