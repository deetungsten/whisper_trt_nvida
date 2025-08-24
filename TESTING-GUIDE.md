# Step-by-Step Testing Guide for Jetson Orin Nano

Follow these steps to test if WhisperTRT Docker setup works correctly on your Jetson Orin Nano.

## Prerequisites Check

### 1. Verify Jetson Setup
```bash
# Check Jetson info
sudo jetson_release

# Check NVIDIA runtime
docker info | grep nvidia
# Should show: Runtimes: nvidia runc
```

### 2. Test GPU Access
```bash
# Test NVIDIA container runtime
docker run --runtime=nvidia --rm nvcr.io/nvidia/l4t-base:r35.2.1 nvidia-smi
# Should show GPU information
```

## Step-by-Step Testing

### Step 1: Clone and Navigate
```bash
cd /path/to/your/project
ls -la
# Should see: Dockerfile, docker-compose.yml, Docker-README.md, etc.
```

### Step 2: Build Container (First Test)
```bash
# Build the image (this will take 10-20 minutes)
docker-compose build

# Check if image was built successfully
docker images | grep whisper-trt
# Should show: whisper-trt   jetson   [IMAGE_ID]   [TIME]   [SIZE]
```

### Step 3: Test Basic Container Launch
```bash
# Start interactive container
docker-compose up whisper-trt

# In the container shell, test Python imports:
python3 -c "import whisper_trt; print('WhisperTRT imported successfully')"
python3 -c "import torch; print(f'PyTorch: {torch.__version__}')"
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
python3 -c "import torch; print(f'GPU count: {torch.cuda.device_count()}')"

# Exit container
exit
```

### Step 4: Download Test Audio
```bash
# Create assets directory and download test file
mkdir -p assets
wget https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0010_8k.wav -O assets/speech.wav

# Verify file downloaded
ls -la assets/
file assets/speech.wav
# Should show: assets/speech.wav: RIFF (little-endian) data, WAVE audio
```

### Step 5: Test Model Loading (Critical Test)
```bash
# Run interactive container
docker-compose up whisper-trt

# Inside container, test model loading:
python3 -c "
from whisper_trt import load_trt_model
print('Loading tiny.en model...')
model = load_trt_model('tiny.en')
print('Model loaded successfully!')
print(f'Model type: {type(model)}')
"

# This will take 2-5 minutes on first run (TensorRT compilation)
# Should end with: "Model loaded successfully!"
```

### Step 6: Test Transcription (Main Functionality)
```bash
# Test with the transcribe profile
docker-compose --profile transcribe up transcribe

# Expected output should include:
# - Model loading messages
# - "Detected language: English"
# - Transcribed text from the audio file
```

### Step 7: Test Performance Profiling
```bash
# Run performance test
docker-compose --profile profile up profile

# Should output timing and memory usage:
# - Load time: X.XX seconds
# - Transcribe time: X.XX seconds  
# - Peak memory: XXX MB
```

### Step 8: Test All Backend Comparisons
```bash
# Test different backends in interactive mode
docker-compose up whisper-trt

# Inside container:
python3 examples/transcribe.py tiny.en assets/speech.wav --backend whisper_trt
python3 examples/transcribe.py tiny.en assets/speech.wav --backend whisper
python3 examples/transcribe.py tiny.en assets/speech.wav --backend faster_whisper
```

### Step 9: Test Audio Device Access (Optional)
```bash
# Check audio devices on host
ls -la /dev/snd/

# Test live transcription (if you have microphone)
docker-compose --profile live up live

# Should start listening for audio input
# Speak into microphone to test real-time transcription
```

## Success Criteria

### ✅ Container Build Success
- Docker build completes without errors
- Image appears in `docker images`

### ✅ GPU Access Success  
- `torch.cuda.is_available()` returns `True`
- `nvidia-smi` works inside container

### ✅ Model Loading Success
- `load_trt_model('tiny.en')` completes without errors
- TensorRT engine compilation succeeds (first run only)

### ✅ Transcription Success
- Audio file transcription produces readable text output
- Processing time < 2 seconds for 20-second audio

### ✅ Performance Success
- WhisperTRT faster than regular Whisper
- Memory usage reasonable (< 500MB for tiny.en)

## Troubleshooting Commands

### If Container Won't Start:
```bash
# Check logs
docker-compose logs whisper-trt

# Check system resources
free -h
df -h
```

### If GPU Not Detected:
```bash
# Restart docker daemon
sudo systemctl restart docker

# Check NVIDIA container runtime
sudo docker info | grep nvidia
```

### If Model Loading Fails:
```bash
# Clear cache and retry
docker volume rm whisper-cache
docker-compose build --no-cache
```

### If Audio Doesn't Work:
```bash
# Check audio permissions
ls -la /dev/snd/
groups $USER

# Test audio on host first
arecord -l
aplay -l
```

## Expected Performance on Jetson Orin Nano

- **First run**: 3-5 minutes (TensorRT compilation)
- **Subsequent runs**: < 1 second startup
- **Transcription (20s audio)**: 0.6-0.9 seconds with tiny.en
- **Memory usage**: 400-500MB with tiny.en

## Final Verification Test

Run this complete test to verify everything works:

```bash
#!/bin/bash
echo "=== WhisperTRT Docker Test ==="
echo "1. Building container..."
docker-compose build

echo "2. Testing GPU access..."
docker run --runtime=nvidia --rm whisper-trt:jetson python3 -c "import torch; print('CUDA:', torch.cuda.is_available())"

echo "3. Downloading test audio..."
mkdir -p assets
wget -q https://www.voiptroubleshooter.com/open_speech/american/OSR_us_000_0010_8k.wav -O assets/speech.wav

echo "4. Running transcription test..."
docker-compose --profile transcribe up transcribe

echo "5. Running performance test..."
docker-compose --profile profile up profile

echo "=== Test Complete ==="
```

If all steps pass, your WhisperTRT Docker setup is working correctly!