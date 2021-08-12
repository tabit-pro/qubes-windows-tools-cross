
ARCH=x64
CC=/usr/bin/x86_64-w64-mingw32-gcc
CXX=/usr/bin/x86_64-w64-mingw32-g++
DLLTOOL=/usr/bin/x86_64-w64-mingw32-dlltool
STRIP=/usr/bin/x86_64-w64-mingw32-strip
WINDRES=/usr/bin/x86_64-w64-mingw32-windres
WINDMC=/usr/bin/x86_64-w64-mingw32-windmc
DDKPATH=/usr/x86_64-w64-mingw32/sys-root/mingw/include/ddk
DEBUG=-U_DEBUG -UDBG -UDEBUG

TARGETS=devcon.exe \
	qubes-vmm-xen-win-pvdrivers-xeniface \
	qubes-vmm-xen-windows-pvdrivers \
	qubes-core-vchan-xen \
	qubes-windows-utils \
	qubes-core-qubesdb \
	qubes-core-agent-windows \
	qubes-gui-common \
	qubes-gui-agent-windows \
	qubes-installer-qubes-os-windows-tools

.PHONY: $(TARGETS)

OUTDIR=$(PWD)/bin/$(ARCH)

PVDRIVERS_VERSION = 8.2.2

ifneq ($(DISTFILES_MIRROR),)
BASE_URL := $(DISTFILES_MIRROR)/qwt-crossbuild
else
BASE_URL = https://xenbits.xenproject.org/pvdrivers/win
endif

PVDRIVERS_URLS := $(BASE_URL)/$(PVDRIVERS_VERSION)/xenbus.tar \
                $(BASE_URL)/$(PVDRIVERS_VERSION)/xeniface.tar \
                $(BASE_URL)/$(PVDRIVERS_VERSION)/xenvbd.tar \
                $(BASE_URL)/$(PVDRIVERS_VERSION)/xennet.tar \
                $(BASE_URL)/$(PVDRIVERS_VERSION)/xenvif.tar

PVDRIVERS_UPSTREAM := $(notdir $(PVDRIVERS_URLS))
PVDRIVERS := $(patsubst %.tar,%-$(PVDRIVERS_VERSION).tar,$(PVDRIVERS_UPSTREAM))

$(PVDRIVERS): %-$(PVDRIVERS_VERSION).tar:
	echo $*
	$(FETCH_CMD) $@.UNTRUSTED "$(filter %$*.tar,$(PVDRIVERS_URLS))"
	grep $@ sources|sed 's:$@:$@.UNTRUSTED:' | sha512sum -c -
	mv $@.UNTRUSTED $@


BINARIES_URL := https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip \
		https://web.archive.org/web/20100818223107/http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe

BINARIES := $(notdir $(BINARIES_URL))

ifneq ($(DISTFILES_MIRROR),)
BINARIES_URL := $(addprefix $(DISTFILES_MIRROR)/qwt-crossbuild/,$(BINARIES))
endif

$(BINARIES):
	$(FETCH_CMD) $@.UNTRUSTED $(filter %/$@,$(BINARIES_URL))
	grep $@ sources|sed 's:$@:$@.UNTRUSTED:' | sha512sum -c -
	mv $@.UNTRUSTED $@

DEVCON := devcon.tar.gz

$(DEVCON):
	rm -fr devcon devcon.UNTRUSTED
	git clone --no-checkout --filter=blob:none --depth=1 --branch=master --single-branch https://github.com/microsoft/Windows-driver-samples.git devcon.UNTRUSTED
	git -C devcon.UNTRUSTED checkout master setup/devcon
	cp sources.devcon devcon.UNTRUSTED/setup/
	cd devcon.UNTRUSTED/setup/ && cat sources.devcon | sha512sum -c -
	tar -czf $(DEVCON) -C devcon.UNTRUSTED/setup devcon

get-sources: $(PVDRIVERS) $(BINARIES) $(DEVCON)
get-sources:
	git submodule update --init --recursive

verify-sources:
	@true

prep: 
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(ARCH)
	rm -f *.msi

all: prep $(TARGETS)

devcon.exe: qubes-windows-utils
	cd devcon/ && \
	$(WINDMC) msg.mc && \
	$(WINDRES) devcon.rc rc.so && \
	$(CXX) -municode -Wno-write-strings -L $(OUTDIR) -I include -D__MINGW__ -DWIN32_LEAN_AND_MEAN=1 -DUNICODE -D_UNICODE *.cpp rc.so -lsetupapi -lole32 -static-libstdc++ -static-libgcc -static -lpthread -o $(OUTDIR)/$@

qubes-vmm-xen-win-pvdrivers-xeniface: 
	$(CC) $@/src/xencontrol/xencontrol.c -I $@/include -lsetupapi -I include -DXENCONTROL_EXPORTS -DUNICODE -shared -o $(OUTDIR)/xencontrol.dll
	cp -f $@/include/xencontrol.h include
	cp -f $@/include/xeniface_ioctls.h include

qubes-vmm-xen-windows-pvdrivers: qubes-vmm-xen-win-pvdrivers-xeniface
	$(CC) $@/src/libxenvchan/*.c -std=c11 -fgnu89-inline -D__MINGW__ -D_INC_TCHAR -DNO_SHLWAPI_STRFCNS -DUNICODE -D_UNICODE -mwindows -D_WIN32_WINNT=0x0600 -L $(OUTDIR) -I include -I $@/include -lxencontrol -Wl,--no-insert-timestamp -DXENVCHAN_EXPORTS -D_NTOS_ -shared -o $(OUTDIR)/libxenvchan.dll
	cp -f $@/include/libxenvchan.h include
	cp -f $@/include/libxenvchan_ring.h include

qubes-core-vchan-xen: qubes-vmm-xen-windows-pvdrivers
	cd $@/windows && \
	CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include" LDFLAGS="-L $(OUTDIR)" make all
	cp -f $@/windows/include/*.h include
	cp -f $@/windows/bin/$(ARCH)/* $(OUTDIR)

qubes-windows-utils: qubes-core-vchan-xen
	cd $@ && \
	CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include" LDFLAGS="-L $(OUTDIR)" make all
	cp -f $@/include/*.h include
	cp -f $@/bin/$(ARCH)/* $(OUTDIR)

qubes-core-agent-windows: qubes-core-qubesdb
	cd $@ && \
	DDK_PATH=$(DDKPATH) WINDRES=$(WINDRES) CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include" LDFLAGS="-L $(OUTDIR)" make all
	cp -fr $@/bin/$(ARCH)/* $(OUTDIR)
	cp -fr $@/bin/$(ARCH)/advertise-tools.exe ./
	cp -fr $@/bin/AnyCPU $(PWD)/bin/

qubes-core-qubesdb: qubes-windows-utils
	cd $@/windows && \
	CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include" LDFLAGS="-L $(OUTDIR)" make all
	cp -f $@/include/*.h include/
	cp -f $@/windows/bin/$(ARCH)/* $(OUTDIR)

qubes-installer-qubes-os-windows-tools:
	cd $@/ && \
	DDK_PATH=$(DDKPATH) WINDRES=$(WINDRES) CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include" LDFLAGS="-L $(OUTDIR)" make all
	cp -fr $@/bin/$(ARCH)/* $(OUTDIR)
	cp $@/iso-README.txt ./
	cp $@/license.rtf ./
	cp $@/qubes-logo.png ./
	cp $@/qubes.ico ./
	cp $@/power_settings.bat ./

qubes-gui-common:
	cp -f $@/include/*.h include

qubes-gui-agent-windows: qubes-gui-common
	cd $@ && \
	DLLTOOL=$(DLLTOOL) STRIP=$(STRIP) DDK_PATH=$(DDKPATH) WINDRES=$(WINDRES) CC=$(CC) ARCH=$(ARCH) CFLAGS="-I $(PWD)/include -mwindows -U__cplusplus" LDFLAGS="-L $(OUTDIR)" make all
	cp -f $@/include/*.h include
	cp -f $@/bin/$(ARCH)/* $(OUTDIR)

