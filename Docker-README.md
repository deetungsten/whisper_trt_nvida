# Docker Deployment for Jetson Orin Nano

This guide explains how to run WhisperTRT in a Docker container on NVIDIA Jetson Orin Nano.

## Prerequisites

- NVIDIA Jetson Orin Nano with JetPack 5.1+ 
- Docker installed with NVIDIA Container Runtime
- At least 4GB of available storage for models and cache

## Quick Start

### 1. Build the Container

```bash
docker-compose build
```

### 2. Download Sample Audio (Optional)

```bash
mkdir -p assets
wget https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0010_8k.wav -O assets/speech.wav
```

### 3. Run Examples

#### Interactive Shell
```bash
docker-compose up whisper-trt
```

#### Transcribe Audio File
```bash
docker-compose --profile transcribe up transcribe
```

#### Profile Performance
```bash
docker-compose --profile profile up profile
```

#### Live Transcription
```bash
docker-compose --profile live up live
```

## Manual Docker Commands

### Build Image
```bash
docker build -t whisper-trt:jetson .
```

### Run Interactive Container
```bash
docker run -it --runtime=nvidia \
  --env NVIDIA_VISIBLE_DEVICES=all \
  --env NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v $(pwd)/assets:/app/assets:ro \
  -v whisper-cache:/root/.cache/whisper_trt \
  whisper-trt:jetson /bin/bash
```

### Transcribe Audio
```bash
docker run --runtime=nvidia \
  --env NVIDIA_VISIBLE_DEVICES=all \
  --env NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v $(pwd)/assets:/app/assets:ro \
  -v whisper-cache:/root/.cache/whisper_trt \
  whisper-trt:jetson \
  python3 examples/transcribe.py tiny.en assets/speech.wav --backend whisper_trt
```

## Volume Mounts

- `./assets:/app/assets:ro` - Mount local audio files (read-only)
- `whisper-cache:/root/.cache/whisper_trt` - Persistent cache for TensorRT engines
- `/dev/snd:/dev/snd` - Audio device access for live transcription

## Troubleshooting

### NVIDIA Runtime Issues
```bash
# Check if NVIDIA runtime is available
docker info | grep nvidia

# Test GPU access
docker run --runtime=nvidia --rm nvidia/cuda:11.4-base-ubuntu20.04 nvidia-smi
```

### Audio Device Issues
```bash
# Check audio devices
ls -la /dev/snd/

# Run with audio access
docker run -it --privileged --device /dev/snd:/dev/snd whisper-trt:jetson
```

### Cache Issues
```bash
# Clear TensorRT cache
docker volume rm whisper-cache

# Check cache contents
docker run --rm -v whisper-cache:/cache busybox ls -la /cache
```

## Performance Notes

- First run will be slower due to TensorRT engine compilation
- Models are cached in the `whisper-cache` volume for subsequent runs
- Use `tiny.en` model for fastest performance on Jetson Orin Nano
- `base.en` provides better accuracy but uses more memory