# This routine:
#   Gets the Qubes private volume
#   Verifies that disk header is nearly all zeros (e.g. never initialized or re-cleared via diskpart's clean command)
#   Verifies that Q drive does not yet exist
#   Formats as "Qubes Private Image" 
#   Assigns letter Q:
#
# Note: Private should always be found on PHYSICALDRIVE1 (in Windows under Qubes, that's: 0=BOOT/1=PRIVATE/2=VOLATILE).
# Note: \\.\PHYSICALDRIVE1 and diskpart's "select disk 1" are assumed to be equivalent.
# Note: This removes the QM00002 serial number check (which fails in Qubes R4.0).

# We can utilize PInvoke to call win32 API to get raw disk handle
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("kernel32.dll")] public static extern IntPtr CreateFile(string lpFileName, int dwDesiredAccess, int dwShareMode, IntPtr lpSecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);
}
"@

# Set $bytecount to disk header size
$blocksize=512
$blockcount=64
$bytecount=$blocksize*$blockcount # number of bytes to check at start of disk to "prove" disk is empty.

# Threshold of unexpected bytes
$maxunexpected=5

# Get raw device with appropriate flags
$handle = [PInvoke]::CreateFile('\\.\PhysicalDrive1', 0x80000000, 6, 0, 3, 0, 0)

# Convert handle to Powershell object
$fs = New-Object System.IO.FileStream ($handle, 'Read', $true)

# Set up array to hold disk header data
$b = [array]::CreateInstance([byte], $bytecount)

# Instead of real error handling around the Read below we'll...
# ...pre-populate with data that should fail the empty if not overwritten by a good read
$b[0] = 255 

# Read raw volume data into array and clean up object
$fs.Read($b, 0, $bytecount) | Out-Null
$fs.Dispose()

# Create flag for whether device is empty
$headerempty = 1

# Create counter for stray non-zero bytes
$nonzerocounter = 0

# Check buffer to ensure for all bytes are zeros
# For some reason, on a new Qubes install, I found two 0x4B aka 75 bytes in the upper half of the first 512-byte block
foreach($byte in $b)
{
	if (($byte -ne 0) -and ($byte -ne 75))
	{
		$nonzerocounter++
	}
}

if ($nonzerocounter -gt $maxunexpected)
{
	$headerempty = 0
}

# Only invoke diskpart if the header is empty and the Q drive is missing.
if (($headerempty -ne 0) -and (-not (Get-PSDrive Q)))
{
@"
  select disk 1
  clean
  convert gpt
  create partition primary
  format quick fs=ntfs label="Qubes Private Image"
  assign letter="Q"
"@|diskpart
}

# Write data to file for debugging
#Set-Content .\disk_header $b -Encoding Byte

