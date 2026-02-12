# 🟢 USE THE OFFICIAL WORKER BASE
FROM runpod/worker-comfyui:5.5.1-base

USER root

# =======================================================
# 1. SYSTEM DEPENDENCIES (Blender Requirements)
# =======================================================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    xvfb \
    xz-utils \
    libgl1 \
    libglib2.0-0 \
    libxrender1 \
    libsm6 \
    libxext6 \
    libxi6 \
    libxkbcommon-x11-0 \
    && rm -rf /var/lib/apt/lists/*

# ⬇️ MANUAL BLENDER DOWNLOAD (Blender 4.1)
RUN wget https://download.blender.org/release/Blender4.1/blender-4.1.0-linux-x64.tar.xz \
    && tar -xvf blender-4.1.0-linux-x64.tar.xz -C /usr/local/ \
    && mv /usr/local/blender-4.1.0-linux-x64 /usr/local/blender \
    && ln -s /usr/local/blender/blender /usr/bin/blender \
    && rm blender-4.1.0-linux-x64.tar.xz

# =======================================================
# 2. PYTHON DEPENDENCIES
# =======================================================
RUN pip install --no-cache-dir numpy pillow opencv-python-headless

# =======================================================
# 3. INSTALL STANDARD CUSTOM NODES
# =======================================================
RUN comfy node install --exit-on-fail comfyui_essentials@1.1.0 --mode remote
RUN comfy node install --exit-on-fail ComfyUI_Comfyroll_CustomNodes
RUN comfy node install --exit-on-fail comfyui-kjnodes@1.2.9
RUN comfy node install --exit-on-fail was-node-suite-comfyui@1.0.2
RUN comfy node install --exit-on-fail comfyui-easy-use@1.3.6
RUN comfy node install --exit-on-fail ComfyUI-TiledDiffusion
RUN comfy node install --exit-on-fail comfyui-inpaint-cropandstitch@3.0.2
RUN comfy node install --exit-on-fail rgthree-comfy@1.0.2512112053
RUN comfy node install --exit-on-fail comfyui-rmbg@3.0.0
RUN comfy node install --exit-on-fail comfyui_layerstyle@2.0.38
RUN comfy node install --exit-on-fail ComfyUI_AdvancedRefluxControl

# =======================================================
# 4. COPY YOUR LOCAL NODES
# =======================================================
# Ensure these names MATCH EXACTLY your GitHub folders
COPY confyUI_ds /comfyui/custom_nodes/comfyui_document_scanner
COPY ComfyUI_SeamlessPattern-master /comfyui/custom_nodes/ComfyUI_SeamlessPattern
COPY comfyui_br /comfyui/custom_nodes/ComfyUI_blender_render

# Install requirements
RUN pip install -r /comfyui/custom_nodes/ComfyUI_blender_render/requirements.txt || true

# =======================================================
# 5. DOWNLOAD MODELS
# =======================================================
RUN wget -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors
RUN wget -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors
RUN wget -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors
RUN wget -O /comfyui/models/clip_vision/sglip2-so400m-patch16-512.safetensors https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors
RUN wget -O /comfyui/models/style_models/flux1-redux-dev.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/flux1-redux-dev.safetensors
RUN wget -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors
RUN wget -O /comfyui/models/upscale_models/4x-UltraSharp.pth https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth
RUN wget -O /comfyui/models/diffusion_models/flux1-dev-fp8-e4m3fn.safetensors https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8-e4m3fn.safetensors

# ✅ BLENDER FILE
RUN mkdir -p /comfyui/models/blender
RUN wget -O /comfyui/models/blender/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# =======================================================
# 6. STARTUP SCRIPT (THE FIX FOR EXIT CODE 2)
# =======================================================
# We write a physical script file instead of using a complex CMD
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "🚀 Starting Virtual Monitor (Xvfb)..."' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo 'echo "⏳ Waiting for Xvfb..."' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo 'echo "✅ Starting RunPod Handler..."' >> /start.sh && \
    echo 'exec python -u /rp_handler.py' >> /start.sh && \
    chmod +x /start.sh

# Use the script as the startup command
CMD ["/start.sh"]
