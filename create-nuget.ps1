Copy-Item msi\installer.msi nugets\Samsung.Tizen.Sdk\data\samsung.tizen.sdk.7.0.100-preview.13.30-x64.msi
Copy-Item msi\installer.msi nugets\Samsung.Tizen.Ref\data\samsung.tizen.ref.7.0.100-preview.13.30-x64.msi
Copy-Item msi\installer.msi nugets\Samsung.Tizen.Runtime\data\samsung.tizen.runtime.7.0.100-preview.13.30-x64.msi

foreach ($dir in (gci nugets)) {
    try {
        Push-Location $dir
        & "C:\Projects\nuget.exe" pack -OutputDirectory ..\..\feed
    } finally {
        Pop-Location
    }
}