This repository is intended to make available Qubes Windows Tools cross compilation with official build environment (aka qubes-builder). It has been tested with R4.1 pre-release version based on Fedora 32 dom0 and Fedora 33 Template VM. In addition to Qway Qubes repository project it has source codes and binaries verification based on git modules and sha512 control sum.

Here is short how-to instructions to build using disposable VM in Qubes R4.1 pre-release. It requires additional private disk space to get all work, 10G is enough.

1. Setup build environment
```
cd ~
sudo dnf -y install git make mock
git clone https://github.com/QubesOS/qubes-builder
cd qubes-builder
make install-deps
make remount
make BUILDERCONF=example-configs/qubes-os-master.conf COMPONENTS=builder-rpm get-sources
```
2. Get QWT sources and extra binaries
```
make BUILDERCONF=example-configs/qubes-os-master.conf BASEURL=https://github.com GIT_PREFIX=tabit-pro/qubes- INSECURE_SKIP_CHECKING=windows-tools-cross COMPONENTS=windows-tools-cross get-sources
```
3. Build QWT iso
```
make BUILDERCONF=example-configs/qubes-os-master.conf COMPONENTS=windows-tools-cross windows-tools-cross-dom0
```
4. Extract result package in disposable VM to get temporary CDROM device available [Note: you may need to add --nosignature to the rpm invocation to extract the ISO.]
```
sudo rpm -Uhv qubes-packages-mirror-repo/dom0-fc32/rpm/qubes-windows-tools*.noarch.rpm
sudo losetup -f /usr/lib/qubes/qubes-windows-tools.iso
```
5. Install QWT to windows qube (it need to be prepared)
```
dom0: qvm-start [windows-qube-name] --cdrom [dispXXXX]:loop0
```
_Warning: Windows 10+ may not recognize a attached CDROM. In this case, you need to disable hibernation mode and restart the VM._
```
C:\Windows\> powercfg -H OFF
```

## Build using Visual Studio 2019

1. Setup build environment

install VS2019 using Visual Studio Installer, install additional components: Python 3, Windows Driver Kit
Make sure that Python executable path is in PATH global environment variable

2. Apply patches

Change directory to %projectdir%\VS2019 and start apply_patches.bat

3. Build projects

Start VS2019, open solution %projectdir%\VS2019\qubes-windows-tools-cross.sln and rebuild all


# Logging

QWT settings are stored in the registry in the section  
HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools

Parameters related to logging:

LogDir: directory for storing .log files  
LogLevel: log level

Each module can have its own settings for the logging level.  
Individual parameters of the logging level are stored in the registry in sections

HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools\<module name>

For example, for qrexec-agent.exe, the logging parameters can be described in the registry in the section

HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools\qrexec-agent

An example of a settings file:

```reg
REGEDIT4

[HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools]
"LogDir"="Q:\\QubesLog"
"LogLevel"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools\advertise-tools]
"LogLevel"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools\qrexec-wrapper]
"LogLevel"=dword:00000005

[HKEY_LOCAL_MACHINE\SOFTWARE\Invisible Things Lab\Qubes Tools\qrexec-agent]
"LogLevel"=dword:00000005
```
