@rem echo %~dp0

pushd %~dp0\..\
patch -Nfs -d qubes-core-vchan-xen -p1 < qubes-core-vchan-xen-mingw-fragments.patch
patch -Nfs -d qubes-core-agent-windows -p1 < qubes-core-agent-windows-mingw-fragments.patch
patch -Nfs -d qubes-windows-utils -p1 < qubes-windows-utils-mingw-fragments.patch
patch -Nfs -d qubes-core-qubesdb -p1 < qubes-core-qubesdb-mingw-fragments.patch
patch -Nfs --binary -d qubes-gui-agent-windows -p1 < qubes-gui-agent-windows-mingw-fragments.patch
patch -Nfs -d qubes-installer-qubes-os-windows-tools -p1 < qubes-installer-qubes-os-windows-tools-mingw-fragments.patch
patch -Nfs -d qubes-vmm-xen-windows-pvdrivers -p1 < qubes-vmm-xen-windows-pvdrivers-mingw-fragments.patch
patch -Nfs -d qubes-vmm-xen-win-pvdrivers-xeniface -p1 < qubes-vmm-xen-win-pvdrivers-xeniface-mingw.patch
patch -Nfs -d qubes-gui-agent-windows -p1 < qubes-gui-agent-windows-destroy.patch
patch -Nfs -d qubes-gui-agent-windows -p1 < qubes-gui-agent-windows-watchdog-disable-session-change.patch
patch -Nfs -d qubes-core-agent-windows -p1 < Bugfix-advertise-tools-issues-error-when-calls-qubes.patch

@rem %patch0 -p1
patch -Nfs -p0 < qubes-core-agent-windows-warn-incompat-proto.patch
patch -Nfs -p0 < qubesdb-daemon-win32-fix.patch
patch -Nfs -p1 < qwt-chkstk.patch
patch -Nfs -p1 < qrexec-store-separator-to-fix-relative-path-construct.patch
patch -Nfs -p1 < qwt-appexeclink.patch
patch -Nfs -p1 < qwt-wait-for-process.patch

patch -Nfs -d qubes-core-qubesdb -p1 < qubes-core-qubesdb-daemon-fix-build-using-VS2019.patch

popd

