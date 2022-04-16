Remove-Item C:\ProgramData\dotnet\workloads\Samsung.* -Recurse

dotnet workload install tizen --source $PSScriptRoot\bin\msi-nupkgs --skip-sign-check
