$bootloaderDirectory = Get-Location
$mcopyPath = "C:\msys64\mingw64\bin\mcopy.exe"


$file = [System.IO.File]::Create(".\bin\disk.img")
$file.SetLength(32MB)
$file.Close()

C:\msys64\mingw64\bin\mformat.exe -i .\bin\disk.img -t 1024 -h 4 -s 16 ::




C:\msys64\mingw64\bin\mcopy.exe -v -i .\bin\disk.img .\bin\stage2.bin ::stage2.bin


$bootloader = [System.IO.File]::ReadAllBytes(".\bin\bootloader.bin")
$disk = [System.IO.File]::OpenWrite(".\bin\disk.img")
$disk.Write($bootloader, 0, $bootloader.Length)
$disk.Close()

C:\msys64\ucrt64\bin\qemu-system-i386 -drive format=raw,file=.\bin\disk.img