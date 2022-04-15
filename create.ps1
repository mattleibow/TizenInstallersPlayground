foreach ($dir in (gci nugets)) {
    try {
        Push-Location $dir/data
        & "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" (gci *.wxs)
        & "C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe" (gci *.wixobj)
    } finally {
        Pop-Location
    }
    try {
        Push-Location $dir
        & "C:\Projects\nuget.exe" pack -OutputDirectory ..\..\feed
    } finally {
        Pop-Location
    }
}