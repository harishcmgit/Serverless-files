# 🟢 USE THE OFFICIAL WORKER BASE
FROM runpod/worker-comfyui:5.5.1-base

USER root

# =======================================================
# 1. SYSTEM DEPENDENCIES (CRITICAL FIXES ADDED HERE)
# =======================================================
# Added 'xvfb' (Virtual Monitor) so Blender doesn't crash
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    blender \
    xvfb \
    libgl1 \
    libglib2.0-0 \
    libxrender1 \
    libsm6 \
    libxext6 \
    libjpeg-dev \
    libpng-dev \
    libxi6 \
    libgconf-2-4 \
    && rm -rf /var/lib/apt/lists/*

# =======================================================
# 2. PYTHON DEPENDENCIES
# =======================================================
RUN pip install --no-cache-dir numpy pillow opencv-python-headless

# =======================================================
# 3. INSTALL CUSTOM NODES
# =======================================================
# Installing your requested nodes
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

# ⚠️ INSTALL THE BLENDER NODE MANUALLY TO ENSURE IT WORKS
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/StartHua/ComfyUI-BlenderAI.git
# Install requirements for BlenderAI node
RUN pip install -r ComfyUI-BlenderAI/requirements.txt || true

# Return to root for local copies
WORKDIR /

# =======================================================
# 4. COPY LOCAL CUSTOM NODES
# =======================================================
# Kept your specific local copies
COPY confyUI_ds /comfyui/custom_nodes/comfyui_document_scanner
COPY ComfyUI_SeamlessPattern-master /comfyui/custom_nodes/ComfyUI_SeamlessPattern
COPY comfyui_br /comfyui/custom_nodes/ComfyUI_blender_render

# =======================================================
# 5. DOWNLOAD MODELS (Your Exact List)
# =======================================================
RUN wget -O /comfyui/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors
RUN wget -O /comfyui/models/clip/clip_l.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/main/clip_l.safetensors
RUN wget -O /comfyui/models/vae/ae.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/ae.safetensors
RUN wget -O /comfyui/models/clip_vision/sglip2-so400m-patch16-512.safetensors https://huggingface.co/google/siglip2-so400m-patch16-512/resolve/main/model.safetensors
RUN wget -O /comfyui/models/style_models/flux1-redux-dev.safetensors https://huggingface.co/camenduru/FLUX.1-dev/resolve/d616d290809ffe206732ac4665a9ddcdfb839743/flux1-redux-dev.safetensors
RUN wget -O /comfyui/models/diffusion_models/flux1-dev.safetensors https://huggingface.co/yichengup/flux.1-fill-dev-OneReward/resolve/main/unet_fp8.safetensors
RUN wget -O /comfyui/models/upscale_models/4x-UltraSharp.pth https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth
RUN wget -O /comfyui/models/diffusion_models/flux1-dev-fp8-e4m3fn.safetensors https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8-e4m3fn.safetensors

# ✅ BLENDER FILE (Moved to /comfyui/models/blender for safety)
RUN mkdir -p /comfyui/models/blender
RUN wget -O /comfyui/models/blender/file.blend https://huggingface.co/Srivarshan7/my-assets/resolve/b61a31e/file.blend

# =======================================================
# 6. STARTUP COMMAND (THE MAGIC FIX)
# =======================================================
# This sets up the fake monitor (:99) so Blender doesn't crash
ENV DISPLAY=:99
CMD bash -c "Xvfb :99 -screen 0 1024x768x24 & exec python -u /rp_handler.py"
