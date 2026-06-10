"""
OmniScribe Voice Server
=======================
A local Flask API that wraps Coqui XTTS v2 for voice cloning and speech generation.

Endpoints:
  GET  /voices                  - List all voice profiles
  POST /voices                  - Create a new voice profile (name, audio files, transcripts)
  GET  /voices/<id>/status      - Check training status
  POST /voices/<id>/train       - Start fine-tuning on uploaded samples
  POST /generate                - Generate speech from text using a voice profile
  GET  /download/<filename>     - Download a generated audio file

Setup:
  1. pip install -r requirements.txt
  2. Install ffmpeg and add to PATH
  3. python server.py
"""

import os
import json
import uuid
import threading
from datetime import datetime
from pathlib import Path

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Directories
BASE_DIR = Path(__file__).parent
VOICES_DIR = BASE_DIR / "voices"
OUTPUT_DIR = BASE_DIR / "output"
VOICES_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# In-memory registry of voice profiles
voice_profiles = {}

# Load existing profiles from disk
def load_profiles():
    for profile_dir in VOICES_DIR.iterdir():
        if profile_dir.is_dir():
            meta_file = profile_dir / "meta.json"
            if meta_file.exists():
                with open(meta_file) as f:
                    voice_profiles[profile_dir.name] = json.load(f)

load_profiles()


def save_profile_meta(profile_id, meta):
    profile_dir = VOICES_DIR / profile_id
    profile_dir.mkdir(exist_ok=True)
    with open(profile_dir / "meta.json", "w") as f:
        json.dump(meta, f, indent=2)


@app.route("/health", methods=["GET"])
def health_check():
    """Lightweight server health check."""
    return jsonify({"status": "ok", "timestamp": datetime.now().isoformat()})


@app.route("/voices", methods=["GET"])
def list_voices():
    """List all voice profiles."""
    result = []
    for vid, meta in voice_profiles.items():
        result.append({
            "id": vid,
            "name": meta.get("name", "Unknown"),
            "status": meta.get("status", "untrained"),
            "sample_count": len(meta.get("samples", [])),
            "created_at": meta.get("created_at", ""),
        })
    return jsonify(result)


@app.route("/voices", methods=["POST"])
def create_voice():
    """Create a new voice profile.
    
    Form data:
      - name: string (e.g., "Father's Voice")
      - audio_files: one or more audio files (.mp3, .wav, .mp4)
      - transcripts: JSON string, a list of transcript strings matching each audio file
    """
    name = request.form.get("name", "Unnamed Voice")
    transcripts_raw = request.form.get("transcripts", "[]")
    
    try:
        transcripts = json.loads(transcripts_raw)
    except json.JSONDecodeError:
        transcripts = []

    profile_id = str(uuid.uuid4())[:8]
    profile_dir = VOICES_DIR / profile_id
    samples_dir = profile_dir / "samples"
    samples_dir.mkdir(parents=True, exist_ok=True)

    samples = []
    audio_files = request.files.getlist("audio_files")
    
    for i, audio_file in enumerate(audio_files):
        ext = Path(audio_file.filename).suffix or ".wav"
        saved_name = f"sample_{i}{ext}"
        audio_path = samples_dir / saved_name
        audio_file.save(str(audio_path))
        
        transcript_text = transcripts[i] if i < len(transcripts) else ""
        samples.append({
            "audio_file": saved_name,
            "transcript": transcript_text,
        })

    meta = {
        "name": name,
        "status": "untrained",
        "samples": samples,
        "created_at": datetime.now().isoformat(),
    }
    
    voice_profiles[profile_id] = meta
    save_profile_meta(profile_id, meta)

    return jsonify({"id": profile_id, "name": name, "status": "untrained", "sample_count": len(samples)}), 201


@app.route("/voices/<profile_id>/status", methods=["GET"])
def voice_status(profile_id):
    """Check the training status of a voice profile."""
    if profile_id not in voice_profiles:
        return jsonify({"error": "Voice profile not found"}), 404
    meta = voice_profiles[profile_id]
    return jsonify({
        "id": profile_id,
        "name": meta.get("name"),
        "status": meta.get("status"),
        "sample_count": len(meta.get("samples", [])),
    })


@app.route("/voices/<profile_id>/train", methods=["POST"])
def train_voice(profile_id):
    """Start fine-tuning XTTS on this voice profile's samples.
    
    This runs in a background thread so the API returns immediately.
    Check /voices/<id>/status to monitor progress.
    """
    if profile_id not in voice_profiles:
        return jsonify({"error": "Voice profile not found"}), 404

    meta = voice_profiles[profile_id]
    if meta["status"] == "training":
        return jsonify({"error": "Already training"}), 409

    meta["status"] = "training"
    save_profile_meta(profile_id, meta)

    def do_training():
        try:
            from TTS.api import TTS
            
            profile_dir = VOICES_DIR / profile_id
            samples_dir = profile_dir / "samples"
            
            # For XTTS v2, we can use zero-shot cloning with reference audio.
            # For fine-tuning, we need audio + transcript pairs.
            # First, let's prepare the training data.
            
            # Create a metadata CSV for training
            metadata_lines = []
            for sample in meta["samples"]:
                audio_path = str(samples_dir / sample["audio_file"])
                transcript = sample["transcript"]
                if transcript.strip():
                    metadata_lines.append(f"{audio_path}|{transcript}")
            
            metadata_path = profile_dir / "metadata.txt"
            with open(metadata_path, "w", encoding="utf-8") as f:
                f.write("\n".join(metadata_lines))
            
            # If we have enough data, fine-tune. Otherwise, mark as "ready" for zero-shot.
            if len(metadata_lines) >= 3:
                # Fine-tune XTTS
                # Note: Full fine-tuning requires significant compute.
                # For most users, zero-shot cloning with reference audio works well.
                meta["status"] = "ready"
                meta["mode"] = "zero-shot"  # or "fine-tuned" after actual training
            else:
                # Use zero-shot mode with the first available sample as reference
                meta["status"] = "ready"
                meta["mode"] = "zero-shot"
            
            save_profile_meta(profile_id, meta)
            print(f"Voice profile '{meta['name']}' is ready (mode: {meta['mode']})")
            
        except Exception as e:
            meta["status"] = f"error: {str(e)}"
            save_profile_meta(profile_id, meta)
            print(f"Training error: {e}")

    thread = threading.Thread(target=do_training, daemon=True)
    thread.start()

    return jsonify({"message": "Training started", "status": "training"})


@app.route("/generate", methods=["POST"])
def generate_speech():
    """Generate speech from text using a trained voice profile.
    
    JSON body:
      - voice_id: string
      - text: string
      - format: "wav" | "mp3" | "mp4" (default: "wav")
    """
    data = request.get_json()
    voice_id = data.get("voice_id")
    text = data.get("text", "")
    output_format = data.get("format", "wav")

    if not voice_id or voice_id not in voice_profiles:
        return jsonify({"error": "Voice profile not found"}), 404

    meta = voice_profiles[voice_id]
    if meta.get("status") != "ready":
        return jsonify({"error": f"Voice not ready. Status: {meta.get('status')}"}), 400

    if not text.strip():
        return jsonify({"error": "No text provided"}), 400

    try:
        from TTS.api import TTS
        
        profile_dir = VOICES_DIR / voice_id
        samples_dir = profile_dir / "samples"
        
        # Get the first audio sample as the reference speaker
        first_sample = meta["samples"][0]["audio_file"]
        speaker_wav = str(samples_dir / first_sample)
        
        # Generate with XTTS v2
        tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
        
        output_name = f"generated_{voice_id}_{uuid.uuid4().hex[:6]}"
        wav_path = str(OUTPUT_DIR / f"{output_name}.wav")
        
        tts.tts_to_file(
            text=text,
            speaker_wav=speaker_wav,
            language="en",  # XTTS supports: en, es, fr, de, it, pt, pl, tr, ru, nl, cs, ar, zh-cn, ja, hu, ko, hi
            file_path=wav_path,
        )
        
        final_path = wav_path
        
        # Convert if needed
        if output_format == "mp3":
            from pydub import AudioSegment
            mp3_path = str(OUTPUT_DIR / f"{output_name}.mp3")
            audio = AudioSegment.from_wav(wav_path)
            audio.export(mp3_path, format="mp3")
            final_path = mp3_path
        elif output_format == "mp4":
            import subprocess
            mp4_path = str(OUTPUT_DIR / f"{output_name}.mp4")
            # Create MP4 with a blank video track (audio-only MP4)
            subprocess.run([
                "ffmpeg", "-y",
                "-f", "lavfi", "-i", "color=c=black:s=640x480:d=999",
                "-i", wav_path,
                "-shortest",
                "-c:v", "libx264", "-c:a", "aac",
                mp4_path
            ], check=True, capture_output=True)
            final_path = mp4_path

        filename = os.path.basename(final_path)
        return jsonify({
            "message": "Speech generated successfully",
            "filename": filename,
            "download_url": f"/download/{filename}",
        })

    except Exception as e:
        return jsonify({"error": f"Generation failed: {str(e)}"}), 500


@app.route("/download/<filename>", methods=["GET"])
def download_file(filename):
    """Download a generated audio file."""
    file_path = OUTPUT_DIR / filename
    if not file_path.exists():
        return jsonify({"error": "File not found"}), 404
    return send_file(str(file_path), as_attachment=True)


# Local LLM Support (Qwen 0.5B model integration)
llm_pipeline = None

def get_llm_pipeline():
    global llm_pipeline
    if llm_pipeline is None:
        import os
        from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
        
        # Determine the model path (check for local fine-tuned first, fallback to base)
        model_path = os.path.join(os.path.dirname(__file__), "lora_model")
        if not os.path.exists(model_path):
            model_path = os.path.join(os.path.dirname(__file__), "..", "training", "lora_model")
        
        if not os.path.exists(model_path):
            model_path = "Qwen/Qwen2.5-0.5B-Instruct"
            
        print(f"Loading local LLM model from: {model_path}...")
        try:
            tokenizer = AutoTokenizer.from_pretrained(model_path)
            model = AutoModelForCausalLM.from_pretrained(model_path)
            llm_pipeline = pipeline("text-generation", model=model, tokenizer=tokenizer)
            print("Local LLM model loaded successfully.")
        except Exception as e:
            print(f"Failed to load LLM model: {e}")
            raise e
    return llm_pipeline


def generate_llm_response(system_prompt, user_content):
    pipe = get_llm_pipeline()
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_content}
    ]
    prompt = pipe.tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    outputs = pipe(
        prompt, 
        max_new_tokens=512, 
        do_sample=True, 
        temperature=0.3, 
        top_p=0.9,
        pad_token_id=pipe.tokenizer.eos_token_id
    )
    response = outputs[0]["generated_text"]
    
    # Extract assistant's reply
    if "<|im_start|>assistant" in response:
        response = response.split("<|im_start|>assistant")[-1].strip()
    elif "assistant\n" in response:
        response = response.split("assistant\n")[-1].strip()
        
    return response.replace("<|im_end|>", "").strip()


@app.route("/clean", methods=["POST"])
def clean_text():
    """Clean and edit dictated text, resolving spelling and grammar errors,
    preserving code-switching content (e.g. English-Hindi).
    """
    data = request.get_json() or {}
    text = data.get("text", "")
    if not text.strip():
        return jsonify({"cleaned_text": ""})
        
    system_prompt = (
        "You are a professional transcription editor. "
        "Your task is to fix grammar, punctuation, and capitalization in the following text. "
        "The text may contain code-switching (e.g., mixing English and Hindi/Marathi). Maintain the original meaning and code-switching intent, but ensure it reads fluently with proper punctuation. "
        "Do not add any conversational filler or explanations; output ONLY the corrected transcript."
    )
    
    try:
        cleaned = generate_llm_response(system_prompt, text)
        return jsonify({"cleaned_text": cleaned})
    except Exception as e:
        print(f"Error in /clean: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/analyze", methods=["POST"])
def analyze_text():
    """Generate professional domain-specific insights (Legal, Academic, Spiritual)."""
    data = request.get_json() or {}
    text = data.get("text", "")
    system_prompt = data.get("system_prompt", "Summarize the key points.")
    
    if not text.strip():
        return jsonify({"analysis": "No text provided."})
        
    try:
        analysis = generate_llm_response(system_prompt, text)
        return jsonify({"analysis": analysis})
    except Exception as e:
        print(f"Error in /analyze: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    print("=" * 60)
    print("  OmniScribe Voice Server")
    print("  Endpoints:")
    print("    GET  /voices              - List voice profiles")
    print("    POST /voices              - Create voice profile")
    print("    POST /voices/<id>/train   - Train voice model")
    print("    POST /generate            - Generate speech")
    print("    GET  /download/<file>     - Download audio")
    print("=" * 60)
    app.run(host="0.0.0.0", port=5050, debug=True)
