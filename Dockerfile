# Use dustynv's jetson-containers which are proven to work
FROM dustynv/pytorch:2.1-r36.2.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
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

# Install basic Python dependencies
RUN pip3 install \
    openai-whisper \
    psutil \
    webrtcvad \
    faster-whisper

# Fix the libnvdla_compiler.so issue on JetPack 36.4.2
RUN wget -q -O - https://repo.download.nvidia.com/jetson/common/pool/main/n/nvidia-l4t-tensorrt/nvidia-l4t-tensorrt_8.6.2.3-1_arm64.deb | \
    tar -Oxf - ./usr/lib/aarch64-linux-gnu/libnvdla_compiler.so > /usr/lib/aarch64-linux-gnu/nvidia/libnvdla_compiler.so

# Install torch2trt from source (this base image has proper TensorRT setup)
RUN git clone https://github.com/NVIDIA-AI-IOT/torch2trt.git /tmp/torch2trt && \
    cd /tmp/torch2trt && \
    python3 setup.py install && \
    rm -rf /tmp/torch2trt

# Install the whisper_trt package
RUN pip3 install -e .

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