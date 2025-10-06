# SSH check

## Load credentials from .env
```powershell
$envData = Get-Content .\.env | Where-Object { $_ -and -not $_.StartsWith('#') } | ConvertFrom-StringData
$sshUser = $envData.SSH_USER
$sshPass = $envData.SSH_PASSWORD
$sshPort = if ($envData.SSH_PORT) { [int]$envData.SSH_PORT } else { 22 }
```

## Test SSH via forwarded port (this should succeed if the container is running)
```powershell
ssh -o StrictHostKeyChecking=no -p $sshPort "$sshUser@127.0.0.1"
```

## Optional: try the container’s bridge IP (will normally time out on Windows host)
```powershell
$containerIp = docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ffmpeg-converter
ssh -o StrictHostKeyChecking=no -p 22 "$sshUser@$containerIp"
```

---

# SMB check
## Assuming you mapped host ports, e.g. 18139 -> 139 and 18445 -> 445
```powershell
$shareHost = '127.0.0.1'
$sharePort = 18445   # replace with whatever you exposed for 445
```

## Map and test ConverterInput
```powershell
New-SmbMapping -LocalPath J: -RemotePath "\\$shareHost\ConverterInput" -TcpPort $sharePort -UserName $sshUser -Password $sshPass -Temporary
Test-Path J:\
Remove-SmbMapping -LocalPath J: -Force
```

## Map and test ConverterOutput
```powershell
New-SmbMapping -LocalPath K: -RemotePath "\\$shareHost\ConverterOutput" -TcpPort $sharePort -UserName $sshUser -Password $sshPass -Temporary
Test-Path K:\
Remove-SmbMapping -LocalPath K: -Force
```


# SSH test ffmpeg
## connect via SSH and run ffmpeg -version
```powershell
ssh -o StrictHostKeyChecking=no -p $sshPort "$sshUser@localhost"
```
```bash
ffmpeg -version
```

## test ffmpeg conversion on a file in the input share
```bash
ffmpeg -y -i /shares/ConverterInput/input.mp4 -c:v libx265 -crf 28 -preset fast -c:a aac -b:a 192 /shares/ConverterOutput/output.mp4
```
## test ffmpeg conversion with NVIDIA GPU acceleration (if available)
```bash
ffmpeg -y -hwaccel cuda -hwaccel_output_format cuda -i /shares/ConverterInput/input.mp4 -c:v hevc_nvenc -preset p5 -c:a copy /shares/ConverterOutput/test_hevc_nvenc.mp4
```
(this didn't work for me. no time to troubleshoot right now)

### If GPU support is missing
- For NVIDIA you need an ffmpeg build compiled with --enable-nvenc. Alpine’s stock ffmpeg may not include it; consider using a base image from nvcr.io/nvidia/ffmpeg or building ffmpeg yourself with the right flags.
- For Intel/AMD, install the corresponding drivers and runtime libraries (VAAPI, Quick Sync, AMF) and confirm the container has the required /dev/dri devices or Windows GPU partitions.