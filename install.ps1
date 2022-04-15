
Remove-Item C:\ProgramData\dotnet\workloads\Samsung.* -Recurse

dotnet workload install tizen `
   --from-rollback-file https://aka.ms/dotnet/maui/main.json `
   --source https://pkgs.dev.azure.com/dnceng/public/_packaging/darc-pub-dotnet-runtime-bd261ea4/nuget/v3/index.json `
   --source https://pkgs.dev.azure.com/dnceng/public/_packaging/darc-pub-dotnet-emsdk-52e9452f-3/nuget/v3/index.json `
   --source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet6/nuget/v3/index.json `
   --source https://api.nuget.org/v3/index.json `
   --source C:\Projects\wix-installer\feed `
   --skip-sign-check `
   --no-cache
