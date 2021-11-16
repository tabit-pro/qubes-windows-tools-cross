if (-not (Get-PSDrive Q) -and (Get-WmiObject Win32_DiskDrive -filter 'DeviceID = "\\\\.\\PHYSICALDRIVE1" AND Partitions = 0'))
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
