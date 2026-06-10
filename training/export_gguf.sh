#!/bin/bash
# export_gguf.sh
# This script merges the trained LoRA adapters into the base model and exports it to GGUF format
# so it can be served locally via Ollama. 
# Note: You can run this directly in your Python script using Unsloth's export functions.

# Unsloth makes exporting extremely easy using python:
cat << 'EOF' > export_model.py
from unsloth import FastLanguageModel

# Load the trained model
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "lora_model", 
    max_seq_length = 2048,
    dtype = None,
    load_in_4bit = True,
)

# Export to GGUF (4-bit quantized)
model.save_pretrained_gguf("omniscribe-model", tokenizer, quantization_method = "q4_k_m")
print("Export complete! You can now load 'omniscribe-model-unsloth.Q4_K_M.gguf' into Ollama.")
EOF

python export_model.py

echo "To add this to Ollama, create a Modelfile:"
echo 'FROM ./omniscribe-model-unsloth.Q4_K_M.gguf' > Modelfile
echo 'TEMPLATE """{{- if .System }}{{ .System }}{{ end }}' >> Modelfile
echo '{{- range $i, $_ := .Messages }}' >> Modelfile
echo '{{- $last := eq (len (slice $.Messages $i)) 1}}' >> Modelfile
echo '{{- if eq .Role "user" }}<|im_start|>user' >> Modelfile
echo '{{ .Content }}<|im_end|>' >> Modelfile
echo '{{- else if eq .Role "assistant" }}<|im_start|>assistant' >> Modelfile
echo '{{ if .Content }}{{ .Content }}{{ else }}<|im_end|>{{ end }}' >> Modelfile
echo '{{- end }}' >> Modelfile
echo '{{- if and $last (ne .Role "assistant") }}' >> Modelfile
echo '<|im_start|>assistant' >> Modelfile
echo '{{- end }}' >> Modelfile
echo '{{- end }}"""' >> Modelfile
echo "PARAMETER stop <|im_start|>" >> Modelfile
echo "PARAMETER stop <|im_end|>" >> Modelfile

echo "Then run:"
echo "ollama create omniscribe-model -f Modelfile"
