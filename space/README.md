---
title: frame1-Hexad
emoji: 🧬
colorFrom: purple
colorTo: blue
sdk: gradio
sdk_version: 6.32.0
app_file: app.py
python_version: "3.12"
startup_duration_timeout: 1h
short_description: 5 small LLMs as one population - route, fuse, couple
license: apache-2.0
models:
  - IFM/K2-Horizon-0.9B
  - paradigma-inc/limite-1b-violetto
  - LiquidAI/LFM2.5-Embedding-350M
  - Qwen/Qwen3.5-0.8B
  - deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B
tags:
  - multi-agent
  - ensemble
  - logit-fusion
  - embeddings
  - zerogpu
---

# frame1-Hexad

Five small open models run as one population, on top of the
[frame1](https://github.com/vv0101v01/frame1) emergence framework (MoonBit, commit `1545a42`).

| Model | Role in the Hexad |
|---|---|
| K2-Horizon-0.9B | general reasoning, planning, code and STEM |
| Limite-1B-Violetto | competition maths |
| DeepSeek-R1-Distill-Qwen-1.5B | long chain-of-thought |
| Qwen3.5-0.8B | fast multilingual chat |
| LFM2.5-Embedding-350M | router, consensus judge, agent coupling graph |

**Tabs**

1. **Router + consensus.** LFM embeds the query and finds the nearest of frame1's 128 agent role cards. Their votes decide which generators answer. Consensus is decided first by a majority on `\boxed{}` answers. Otherwise the answer most similar to the others (LFM cosine) wins.
2. **Limite ⊕ R1 fusion.** The two models share 151,643 Qwen2 token ids, so they are decoded together at the token level. Each step samples from the product (log-linear) or the mixture of the two distributions, with α weighting Limite.
3. **frame1 coupling graph.** Port of frame1 module 25: symmetric k-NN on the LFM vectors, heat-kernel weights, cross-family bridges and a Kruskal repair pass. Compared with frame1's ring, λ₂ rises from 0.0024 to 0.540.
4. **Diagnostics.** Shows the load status of each model. It also checks that the HF-transformers LFM encoder reproduces the llama.cpp Q8_0 vectors frame1 was built from.

`data/` holds the 128 role cards, their int8 LFM vectors (frame1 module 26) and the frame1 MoonBit trace for 128 agents × 640 steps.

Runs on ZeroGPU. All five models are loaded in bf16, about 10 GB of VRAM in total.
