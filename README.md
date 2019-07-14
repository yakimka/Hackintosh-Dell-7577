# Инструкция по установке hackintosh для Dell 7577

* [Описание](#description)
  + [Примечания](#notes)
  + [Известные проблемы](#known-bugs)
  + [Протестировано](#specs)
  + [Требования](#requirements)
* [Создание загрузочной флешки](#create-usb)
  + [В MacOS](#create-usb-macos)
  + [В Windows](#create-usb-windows)
* [Установка](#installation)
* [После установки](#post-installation)
  + [Установка Clover bootloader](#install-clover-bootloader)
  + [Настройка Clover и системы](#configure-clover)
  + [Отключить гибернацию](#turn-off-hibernation)
* [Использованные материалы](#references)

## <a name="description"></a> Описание

```plaintext
Clover USB Files:
 - drivers64UEFI: HFSPlus.efi (for HFS+ fs), apfs.efi (for apfs fs)

 - kexts/Other:
   - ApplePS2SmartTouchpad: For initial trackpad & keyboard support
   - FakeSMC: SMC emulator
   - RealtekRT8111: Kext for ethernet support
   - SATA-100-series-unsupported:
   - USBInjectAll: Injecting USB ports (even for recognizing the bootable USB)

 - config.plist: Initial SMBIOS, USBInjectAll dsdt patches, port limit patches (for usb 3.0)

----------------------------------

Clover Post-Install Files:
 - drivers64UEFI: HFSPlus.efi (for HFS+ fs), apfs.efi (for apfs fs)

 - /L/E Kexts:
   - ACPIBatteryManager: Kext for battery status
   - AppleBacklightFixup: Kext for backlight control
   - CodecCommander: Kext for solving 'no audio' after sleep
   - VoodooPS2Controller: Kext for keyboard

 - kexts/Other:
   - AppleALC: Kext for audio
   - AppleBacklightFixup: Kext for backlight control even in recovery
   - FakeSMC: SMC emulator
   - Lilu: Generic kext patches
   - RealtekRT8111: Kext for ethernet support
   - SATA-100-series-unsupported:
   - USBInjectAll: Injecting USB ports
   - VoodooI2C*: Kext for precision trackpad
   - VoodooPS2Controller: Kext for keyboard
   - WhateverGreen: Lilu plugin for various iGPU patches

 - config.plist:
   - DSDT Fixes: FixHPET, FixHeaders, FixIPIC, FixRTC, FixTMR
   - DSDT Patches: IGPU, IMEI, HDEF, OSI, PRW, VoodooI2C, brightness control patches
   - WhateverGreen properties: Disable unused ports, increase VRAM from 1536->2048 MB
   - Kernel and Kext Patches: DellSMBIOS, AppleRTC, KernelLapic, KernelPm
   - Kernel To Patch: MSR 0xE2, Panic kext logging
   - Kexts to Patch: I2C, SSD Trim, AppleALC patches
   - SMBIOS

 - patched:
   - SSDT-ALS0: Fake ambient light sensor
   - SSDT-BRT6: Brightness control via keyboard
   - SSDT-Disable_DGPU: Disable discrete GPU (Nvidia)
   - SSDT-I2C: VoodooI2C GPIO pinning & disabling VoodooPS2 kext for trackpads and mouses
   - SSDT-PNLF: Backlight ssdt
   - SSDT-PRW: SSDT for usb instant wake
   - SSDT-UIAC: Injecting right usb ports (coniguration for usbinjectall kext)
   - SSDT-XCPM: Injecting plugin-type for power management
   - SSDT-XOSI: Faking OS for the ACPI
   - SSDT_ALC256: CodecCommander config for ALC256 (removes headphone noise)
```

### <a name="notes"></a> Примечания

- Работающий хакинтош на 10.14 (Mojave) и 10.13.x (High Sierra)
- Нет поддрежки 4К дисплея *(у меня FullHD ноутбук)*. Но @Nihhaar считает его получится подключить с помощью `его файлов` + `CoreDisplayFixup.kext` + `DVMT patch`
- HDMI не работает, потому что он подключен к Nvidia карте, которую мы отключили (для Optimus ноутбуков невозможно завести дискретное видео)

### <a name="known-bugs"></a> Известные проблемы

- Встроенный Wi-Fi не работает (нужно заменить модель на совместимый, например Broadcomm BCM94352Z)
- SDCard reader (возможно не хватает нескольких кекстов)
- Audio via headphones after sleep (This actually worked on previous releases, so may be need to downgrade AppleALC to tested version like 1.2.8)
- Built-in mic for headphones may not work

### <a name="specs"></a> Протестировано

- Intel i5-7300HQ CPU
- Intel HD Graphics 630 / nVidia GTX 1050
- 8GB DDR4 RAM
- 15.6" 1080p IPS Display
- 256GB Samsung 970 EVO M.2 SSD / 256GB Samsung 850 EVO SATA SSD

### <a name="requirements"></a> Требования

- Установить параметры BIOS:
  - Отключить Legacy Option ROMs
  - Изменить SATA operation на AHCI (If already using windows, google how to)
  - Отключить Secure Boot
  - Отключить VT для Direct I/O (VT-d)
- USB флешка размером >= 16GB, желательно USB 2.0 (с 3.0 у меня не получилось установить)

## <a name="create-usb"></a> Создание загрузочной флешки

Флешку стоит брать USB 2.0, так как установить систему c USB 3.0 у меня не получилось (в установленной системе будут работать оба стандарта). Если нет 2.0 флешки, то можно попробовать установить систему через USB 2.0 хаб (я не пробовал, но на форумах говорят что работает)

### <a name="create-usb-macos"></a> В MacOS

1. Вставить флешку в компьютер
2. Вводим в терминал команду `diskutil list` и запоминаем номер диска флешки (diskX, где X - номер)
3. Создаем разделы: `diskutil partitionDisk /dev/diskX 2 MBR FAT32 "CLOVER EFI" 200Mi HFS+J "install_osx" R`
4. Копируем файлы для установки `sudo "/Applications/Install macOS Mojave.app/Contents/Resources/createinstallmedia" --volume /Volumes/install_osx`
5. [Скачиваем](https://sourceforge.net/projects/cloverefiboot/files/Installer/) последнюю версию Clover и запускаем установщик
6. Выбираем раздел "CLOVER EFI" для установки
7. Выбираем "Настроить" и отмечаем пункты
    - Установить Clover только для UEFI загрузки ("Установить Clover на раздел ESP" выберется автоматически)
    - OSXAptioFix3Drv (Драйверы для UEFI закгрузки -> Memory fix drivers)
8. Начать установку
9. Раскладываем по своим местам файлы из директории USB Files этого репозитория

```plaintext
# serj @ MacBook-Pro-Serj in ~ [21:24:45]
$ diskutil list
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *250.1 GB   disk0
   1:                        EFI EFI                     209.7 MB   disk0s1
   2:                 Apple_APFS Container disk2         249.8 GB   disk0s2

/dev/disk1 (internal):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                         250.1 GB   disk1
   1:                        EFI BOOT                    576.7 MB   disk1s1
   2:           Linux Filesystem                         249.5 GB   disk1s2

/dev/disk2 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +249.8 GB   disk2
                                 Physical Store disk0s2
   1:                APFS Volume MacOS                   50.2 GB    disk2s1
   2:                APFS Volume Preboot                 22.3 MB    disk2s2
   3:                APFS Volume Recovery                515.8 MB   disk2s3
   4:                APFS Volume VM                      20.5 KB    disk2s4
   5:                APFS Volume Steam                   9.7 GB     disk2s5

/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *31.5 GB    disk3
   1:             Windows_FAT_32 KINGSTON                31.5 GB    disk3s1

# serj @ MacBook-Pro-Serj in ~ [21:24:55]
$ diskutil partitionDisk /dev/disk3 2 MBR FAT32 "CLOVER EFI" 200Mi HFS+J "install_osx" R
Started partitioning on disk3
Unmounting disk
Creating the partition map
Waiting for partitions to activate
Formatting disk3s1 as MS-DOS (FAT32) with name CLOVER EFI
512 bytes per physical sector
/dev/rdisk3s1: 403266 sectors in 403266 FAT32 clusters (512 bytes/cluster)
bps=512 spc=1 res=32 nft=2 mid=0xf8 spt=32 hds=32 hid=2 drv=0x80 bsec=409600 bspf=3151 rdcl=2 infs=1 bkbs=6
Mounting disk
Formatting disk3s2 as Mac OS Extended (Journaled) with name install_osx
Initialized /dev/rdisk3s2 as a 29 GB case-insensitive HFS Plus volume with a 8192k journal
Mounting disk
Finished partitioning on disk3
/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *31.5 GB    disk3
   1:                 DOS_FAT_32 CLOVER EFI              209.7 MB   disk3s1
   2:                  Apple_HFS install_osx             31.3 GB    disk3s2

# serj @ MacBook-Pro-Serj in ~ [21:26:38]
$ sudo "/Applications/Install macOS Mojave.app/Contents/Resources/createinstallmedia" --volume /Volumes/install_osx
Password:
Ready to start.
To continue we need to erase the volume at /Volumes/install_osx.
If you wish to continue type (Y) then press return: Y
Erasing disk: 0%... 10%... 20%... 30%... 100%
Copying to disk: 0%... 10%... 20%... 30%... 40%... 50%... 60%... 70%... 80%... 90%... 100%
Making disk bootable...
Copying boot files...
Install media now available at "/Volumes/Install macOS Mojave"
```

![f8c2c7d0.png](assets/f8c2c7d0.png)

![53e9bb41.png](assets/53e9bb41.png)

![bc48515c.png](assets/bc48515c.png)

![0311f010.png](assets/0311f010.png)

![1a5ee4d7.png](assets/1a5ee4d7.png)

### <a name="create-usb-windows"></a> В Windows

1. Скачиваем BootDiskUtility [отсюда](http://cvad-mac.narod.ru/index/bootdiskutility_exe/0-5)
2. Распаковываем утилиту в любую папку.
3. Скачиваем образ macOS [отсюда](https://mac-ru.net/viewtopic.php?t=1402), [отсюда](https://mac-ru.net/viewtopic.php?t=41), [отсюда](https://nnmclub.to/forum/viewtopic.php?t=1069291) или с [магнет-ссылки](http://магнит.tk/#magnet:?dn=BDUOSXDISTR&xt=urn:btih:64125b9f1387632e1b35b8da27eba422f9821d43) или из [меги](https://mega.nz/#!5wgzXQhR!uQHg6rSwJ5FH-oOWphm0HZxv1fqlaNfb1a_sKgzMjGI)
4. Распаковываем образ из архива.
5. Открываем BootDiskUtility, заходим в секцию настроек, в Clover bootloader source выбираем Not install (В моем случае BDU неправильно распаковывала установщик, поэтому сделаем это вручную).
6. Выбираем свое USB-устройство, нажимаем Format Drive.
7. [Скачиваем](https://sourceforge.net/projects/cloverefiboot/files/Bootable_ISO/) ISO образ Clover. Распаковываем с помощью 7-zip сначала архив, а затем и сам iso образ.
8. Копируем EFI, Library, usr в корень "CLOVER EFI" раздела.
9. Из EFI/CLOVER/drivers/off/ копируем ApfsDriverLoader.efi, AudioDxe.efi, DataHubDxe.efi, FSInject.efi, OsxAptioFix3Drv.efi, SMCHelper.efi в EFI/CLOVER/drivers/UEFI/
10. Раскладываем по своим местам файлы из директории USB Files этого репозитория

>На этом шаге у вас уже должен быть скачан образ macOS в виде 5.hfs.

1. Нажимаем на значок `+` рядом с названием USB. Если вы ничего не меняли в настройках, то у вас появится два раздела, один из которых будет иметь название `CLOVER`, а другой `NONAME`
2. Выбираем `Part2`, который имеет название `NONAME`. Нажимаем кнопку Restore Partition и указываем прежде скачанный `5.hfs`. Начнется запись образа на USB.

![d22c8dee.png](assets/d22c8dee.png)

![af42655e.png](assets/af42655e.png)

![9bf6257a.png](assets/9bf6257a.png)

![981b037e.png](assets/981b037e.png)

![89f15d6f.png](assets/89f15d6f.png)

![d9ab9c76.png](assets/d9ab9c76.png)

## <a name="installation"></a> Установка

- Во время загрузки ноутбука постоянно нажимайте F12, чтобы появилось "one-time boot-menu" в котором нужно выбрать созданную несколькими шагами ранее флешку
- Выберите *install_osx* в Clover (желательно с опцией -v)
- Откройте *Дисковую утилиту* и отформатируйте раздел в apfs и назначьте ему метку (например MacOS)
- Теперь система автоматически перезагрузится. Загрузитесь в Clover снова, но теперь выберите *Install macOS High Sierra* (или *Install macOS Mojave*) вместо *install_osx*

## <a name="post-installation"></a> После установки

### <a name="install-clover-bootloader"></a> Установка Clover bootloader

- Скачать [clover](https://sourceforge.net/projects/cloverefiboot/files/Installer/)
- Запустить установщик
- Сменить цель установки на *"Target Volume"*
- Выбрать *Настроить*
- Отметить "Установить Clover только для UEFI загрузки" ("Установить Clover на раздел ESP" выберется автоматически)
- Отметить *"OsxAptioFix3Drv-64"* from Drivers64UEFI
- Отметить *"EmuVariableUefi-64.efi"* from Drivers64UEFI
- Отметить *"Install RC scripts on target volume"*

### <a name="configure-clover"></a> Настройка Clover и системы

- Replace the existing config.plist with the config.plist from *“Clover Post-Install Files”*
- Add the two EFI drivers from *“Clover Post-Install Files”/drivers64UEFI* to `<EFI Partition>/EFI/CLOVER/drivers64UEFI`, and remove VBoxHfs-64.efi from /EFI/CLOVER/drivers64UEFI
- Add the included SSDTs in *patched* folder into your `<EFI Partition>/EFI/CLOVER/ACPI/patched` folder
- Copy all of the kexts that are located in *Clover Post-Install Files/"Clover/Other Kexts"* folder to `<EFI Partition>/EFI/Clover/Other` on your system.
- Copy all of the kexts that are located in *Clover Post-Install Files/"/L/E Kexts"* folder to `/Library/Extensions` on your system.
- Run *Scripts/fixPermissions.sh* from given release as root to fix kext permissions
- Reboot the laptop and boot with '-f' command line option (press space at clover)
- Rebuild the cache using `sudo kextcache -i /`
- Reboot  

### <a name="turn-off-hibernation"></a> Отключить гибернацию

```bash
sudo pmset -a hibernatemode 0
sudo rm /var/vm/sleepimage
sudo mkdir /var/vm/sleepimage
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
sudo pmset -a powernap 0
```

## <a name="references"></a> Использованные материалы

1. [Установка Mac OS X на Intel-PC – Telegraph](https://telegra.ph/Ustanovka-Mac-OS-X-na-Intel-PC-08-18-2)
2. [GitHub - meixiaofei/Dell7570_MacOs_Clover: This project targets at giving the relatively complete functional ```macOS(what I use is 13.3)``` for Dell 7570, and all were have been driven except 940m and wifi.](https://github.com/meixiaofei/Dell7570_MacOs_Clover)
3. [GitHub - Nihhaar/Hackintosh-Dell-7567: Guide for installing macOS Mojave & High Sierra on Dell Inspiron 7567 Gaming Laptop](https://github.com/Nihhaar/Hackintosh-Dell-7567)
4. [[Guide] Booting the OS X installer on LAPTOPS with Clover \| tonymacx86.com](https://www.tonymacx86.com/threads/guide-booting-the-os-x-installer-on-laptops-with-clover.148093/)
5. [How to create a bootable installer for macOS - Apple Support](https://support.apple.com/en-us/HT201372)
6. [How to install Clover Bootloader on USB from Windows and Linux](https://www.aioboot.com/en/clover-bootloader-windows/)
