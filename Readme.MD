# Master volume sync for Creative Soundblaster 

I have the problem, that I can not control the volume of my sourround sound speakers using spdif output by changing the master volume in Windows. But changing the Volume of the recording device "What u hear" seemed to change the master volume.

Therefore I made a small application that syncs the volume of the "What u hear" recording device to the current master volume.

The application runs as a service and can be exited and configured via the icon in the notification area. There you can also configure which output device is used for the master volume and which device is the "What u hear" recording device.

To install the application you just need to download and execute the "MasterVolumeSync.msi" file. (You can find it [here](https://github.com/nicojeske/MasterVolumeSync/releases/latest))

Alternatively you can install the application via `winget` in the commandline:

```powershell
winget install --id NicoJeskeIT.MasterVolumeSync
```

To run the application you will need to install .NET 6.0. from Microsoft. When trying to start the app without having it installed you will get a pop-up guiding you to the download path. Otherwise you can download it [here](https://dotnet.microsoft.com/en-us/download/dotnet/6.0/runtime?cid=getdotnetcore) directly from Microsoft. Just make sure to download it under the point "Run desktop apps".

The application is tested with the following sound cards:

- Sound BlasterX AE-5 Plus
- Creative Sound Blaster Z/Zx

## Credit

Icon: [Music vector created by studiogstock - www.freepik.com](https://www.freepik.com/vectors/music)
