
# Make Tizen MSI Installers

On Windows, .NET uses .msi installers to track and manage worklaods and packs between Visual Studio and the CLI.

Right now Tizen just has the .nupkg for the file based system. This repo attempts to correctly wrap the packages
in .msi installers and installer packages for consumption by VS and/or the CLI.

## `build.ps1`

This script takes the .nupkg files and wraps them into msi files which is then wrapped back into .nupkg.

The reason for the double wrap is because although dotnet is using .nupkg for the actual work, Visual Studio
requires that it be done via .msi installers per CPU architecture. And then the .nupkg that wraps the .msi
is just for the fact that the CLI uses NuGet to aquire and install things.

The implementation of this script just runs a MSBuild project that takes the .nupkg files from a source (in
this case I manually downloaded all the Tizen packages from nuget.org) and generates all the other packaging.

All the tools used by this process are tools found in dotnet/arcade and are available on the public dotnet-eng
NuGet feed: https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-eng/nuget/v3/index.json

### Required Files

The files used by the build process are 2 types:

 - `*.nupkg`  
   These are the actual packages to wrap.
 - `vs-workload.props`  
   This file is used to set properties for the build as the convert.proj is reusable.  
   There is a different version used in this file to the NuGet SemVer version as the .msi installers require a
   4-part, integer-based version. So the current pattern we have been using is to take the NuGet version of
   `7.0.100-preview.13.30` and strip out the "preview" part and just use the build number `7.0.100.30`.  
   This does required that all the previews of the `7.0.100` version keep incrementing the build number. For
   example, if there is a preview 13 build with version `7.0.100-preview.13.30`, then even if there is a
   preview 14, the build must be incremented and not restarted: `7.0.100-preview.14.31`. To restart the
   version build, you will have to increment the 3rd version component to be something along the lines of
   `7.0.101` which will result in a SemVer version of `7.0.101-preview.14.1` and a .msi version of `7.0.101.1`.

## `install-manifest.ps1`

This script is a modified version of the script found at:

https://github.com/Samsung/Tizen.NET/blob/main/workload/scripts/workload-install.ps1

The modifications are to remove and worklaod/pack installation. All that it does not is make sure the workload
manifest is on disk for the next/future installation of the workloads.

## `install-tizen.ps1`

This script is just the basic dotnet command to install a workload:

```
dotnet workload install tizen --source $PSScriptRoot\bin\msi-nupkgs --skip-sign-check
```

> There is an additoinal line in the script to remove the installation cache of .msi files for testing
> purposes.
> 
> The `--skip-sign-check` argument on the install is to disable the signing check during installation
> because I have not signed these files as I do not have access to any Samsung certificates.
