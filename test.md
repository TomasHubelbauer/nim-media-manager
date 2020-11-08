# MarkRight Test

This is a test of the same tutorial, but using MarkRight.

## Installation

```sh
# TODO: Check Node as a prerequisite
$platform = node -e "console.log({ win32: 'windows', darwin: 'macos' }[process.platform] || process.platform)"
$data = Invoke-WebRequest https://api.github.com/repos/dom96/choosenim/releases/latest | ConvertFrom-Json
$version = $data.tag_name.substring(1)
$name = "^choosenim-${version}_${platform}_amd64(.exe)?$"
$asset = ($data.assets | where { $_.name -match $name })[0]
if (-not (Test-Path $asset.name)) {
  echo dl
  Invoke-WebRequest $asset.browser_download_url -OutFile $asset.name
}

# Use `--firstInstall` to add Nim to %PATH%
Start-Process $asset.name -ArgumentList "stable -y --firstInstall"

# TODO: Do not place this if Nim is already in PATH and remove it if needed
echo "CALL $HOME\.nimble\bin\nim" | Out-File nim.cmd -Encoding ASCII
```

```sh
nim -v
```

```stdout
Nim Compiler Version 1.4.0 [Windows: amd64]
Compiled at 2020-10-18
Copyright (c) 2006-2020 by Andreas Rumpf

active boot switches: -d:release
```

Looks like there is going to be a problem with the PATH placement and it not
being picked up because the CMD can't save it as it always needs to be called
using the dotslash and that can't be worked around in a way that would stick
across session it seems: https://superuser.com/a/1373057/490452

So we'll need to figure out how to add Nim to PATH in a way that the next shell
block sees immediately. Or maybe just tank the document and tell the user to log
in and out and retry?
