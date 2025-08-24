# Multi-stage build for WhisperTRT on Jetson Orin Nano
FROM nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_MODULE_LOADING=LAZY

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    libsndfile1 \
    portaudio19-dev \
    python3-pyaudio \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY setup.py .
COPY whisper_trt/ whisper_trt/

# Install PyTorch and dependencies for Jetson
RUN pip3 install --upgrade pip setuptools wheel

# Install whisper and torch2trt dependencies
RUN pip3 install \
    openai-whisper \
    torch2trt \
    pyaudio \
    psutil \
    faster-whisper \
    webrtcvad \
    && pip3 install -e .

# Create cache directory with proper permissions
RUN mkdir -p /root/.cache/whisper_trt && \
    chmod 755 /root/.cache/whisper_trt

# Copy examples and assets
COPY examples/ examples/

# Create assets directory for audio files
RUN mkdir -p assets

# Expose port for any potential web services
EXPOSE 8000

# Set default command
CMD ["python3", "examples/transcribe.py", "--help"]