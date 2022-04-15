try {
    Push-Location msi
    & "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" installer.wxs -o installer.wixobj
    & "C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe" installer.wixobj
} finally {
    Pop-Location
}