# FFmpeg Converter Docker Container

A minimal Docker container based on Alpine Linux with ffmpeg, ffprobe, SMB shares, and SSH access.

## Features

- **Base**: Alpine Linux (minimal footprint)
- **Tools**: ffmpeg, ffprobe
- **SSH Server**: OpenSSH for remote command execution
- **SMB Shares**: Two shared folders accessible via SMB protocol
  - `\\container\ConverterInput` → `/shares/ConverterInput`
  - `\\container\ConverterOutput` → `/shares/ConverterOutput`

## Quick Start

### Build the Image

```bash
docker build -t ffmpeg-converter .
```

### Run the Container

```bash
docker run -d \
  --name ffmpeg-converter \
  -p 2222:22 \
  -p 139:139 \
  -p 445:445 \
  -e SSH_USER=converter \
  -e SSH_PASSWORD=your_secure_password \
  -v ./input:/shares/ConverterInput \
  -v ./output:/shares/ConverterOutput \
  ffmpeg-converter
```

### Using Docker Compose

```bash
docker-compose up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_USER` | `converter` | SSH and SMB username |
| `SSH_PASSWORD` | `changeme` | SSH and SMB password |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |

## Usage

### SSH Access

Connect via SSH and run ffmpeg commands:

```bash
ssh -p 2222 converter@localhost

# Inside the container, run ffmpeg commands
ffmpeg -i /shares/ConverterInput/input.mp4 -c:v libx264 /shares/ConverterOutput/output.mp4
```

### SMB Access

Access the shares from Windows:

```
\\localhost\ConverterInput
\\localhost\ConverterOutput
```

Or from Linux:

```bash
smbclient //localhost/ConverterInput -U converter
```

### Remote FFmpeg Execution

Execute ffmpeg commands remotely via SSH:

```bash
ssh -p 2222 converter@localhost "ffmpeg -i /shares/ConverterInput/video.mp4 -c:v libx264 -crf 23 /shares/ConverterOutput/converted.mp4"
```

## Ports

- **22**: SSH (mapped to host port 2222 in examples)
- **139**: SMB (NetBIOS)
- **445**: SMB

## Example FFmpeg Commands

### Convert video to H.264

```bash
ffmpeg -i /shares/ConverterInput/input.mp4 -c:v libx264 -crf 23 -c:a aac /shares/ConverterOutput/output.mp4
```

### Extract audio

```bash
ffmpeg -i /shares/ConverterInput/video.mp4 -vn -c:a copy /shares/ConverterOutput/audio.m4a
```

### Get video information

```bash
ffprobe /shares/ConverterInput/video.mp4
```

### Batch conversion

```bash
for file in /shares/ConverterInput/*.mp4; do
  filename=$(basename "$file" .mp4)
  ffmpeg -i "$file" -c:v libx264 -crf 23 "/shares/ConverterOutput/${filename}_converted.mp4"
done
```

## Security Notes

- **Change the default password**: Always set a strong password using the `SSH_PASSWORD` environment variable
- **Firewall**: Only expose necessary ports to trusted networks
- **Network isolation**: Consider using Docker networks to isolate the container
- **Volume permissions**: Ensure proper file permissions on mounted volumes

## Troubleshooting

### Check container logs

```bash
docker logs ffmpeg-converter
```

### Enter the container

```bash
docker exec -it ffmpeg-converter /bin/bash
```

### Verify ffmpeg installation

```bash
docker exec ffmpeg-converter ffmpeg -version
```

### Test SMB connection

```bash
smbclient -L localhost -U converter
```
