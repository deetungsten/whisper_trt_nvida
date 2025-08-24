# Use NVIDIA Jetson container with TensorRT support
FROM nvcr.io/nvidia/l4t-jetpack:r36.3.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_MODULE_LOADING=LAZY

# Install system dependencies including Rust
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    libsndfile1 \
    portaudio19-dev \
    python3-pyaudio \
    ffmpeg \
    curl \
    wget \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for compiling tokenizers from source
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY setup.py .
COPY whisper_trt/ whisper_trt/

# Install PyTorch wheel for Jetson (ARM64)
RUN pip3 install --upgrade pip setuptools wheel

# Download and install PyTorch for Jetson
RUN wget https://developer.download.nvidia.com/compute/redist/jp/v60/pytorch/torch-2.3.0-cp310-cp310-linux_aarch64.whl -O torch-2.3.0-cp310-cp310-linux_aarch64.whl && \
    pip3 install torch-2.3.0-cp310-cp310-linux_aarch64.whl && \
    rm torch-2.3.0-cp310-cp310-linux_aarch64.whl

# Install Python dependencies (except torch2trt)
RUN pip3 install \
    openai-whisper \
    pyaudio \
    psutil \
    webrtcvad

# Install faster-whisper without tokenizers dependency first, then install compatible tokenizers
RUN pip3 install --no-deps faster-whisper && \
    pip3 install "tokenizers>=0.14.1" ctranslate2 huggingface-hub

# Fix TensorRT library links and install torch2trt
RUN ln -s /usr/lib/aarch64-linux-gnu/libnvdla_compiler.so /usr/lib/libnvdla_compiler.so || true && \
    git clone https://github.com/NVIDIA-AI-IOT/torch2trt.git /tmp/torch2trt && \
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