$bootloaderDirectory = Get-Location
$mcopyPath = "C:\msys64\mingw64\bin\mcopy.exe"


$file = [System.IO.File]::Create(".\bin\disk.img")
$file.SetLength(32MB)
$file.Close()

C:\msys64\mingw64\bin\mformat.exe -i .\bin\disk.img ::




C:\msys64\mingw64\bin\mcopy.exe -v -i .\bin\disk.img .\bin\bootstage2.bin ::bootstage2.bin


$bootloader = [System.IO.File]::ReadAllBytes(".\bin\bootloader.bin")
$disk = [System.IO.File]::OpenWrite(".\bin\disk.img")
$disk.Write($bootloader, 0, $bootloader.Length)
$disk.Close()

C:\msys64\ucrt64\bin\qemu-system-i386 -boot menu=on -drive file=.\bin\disk.img,format=raw,if=none,id=bootdrive -device ide-hd,drive=bootdrive,cyls=65,heads=16,secs=63