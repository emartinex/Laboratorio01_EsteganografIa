#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
for cmd in steghide ffmpeg ffprobe cmp sha256sum; do
 command -v "$cmd" >/dev/null || { echo "Falta dependencia: $cmd" >&2; exit 1; }
done
mkdir -p resultados
out=$(mktemp -d resultados/comprobacion-XXXXXX)
printf 'CASO AULA-01\nControl: FORENSE-2026\n' > "$out/mensaje.txt"
pass='AulaForense-2026!'
for name in jardin.jpg jardin.bmp ambiente.wav tonos.wav; do
 steghide embed -cf "portadores/$name" -ef "$out/mensaje.txt" -sf "$out/$name" -p "$pass"
 steghide extract -sf "$out/$name" -xf "$out/$name.txt" -p "$pass"
 cmp "$out/mensaje.txt" "$out/$name.txt"
 printf 'CORRECTO: %s\n' "$name"
done
if steghide extract -sf "$out/jardin.jpg" -xf "$out/incorrecto.txt" -p 'Equivocada-01' >"$out/control_negativo.log" 2>&1; then
 echo 'FALLO: extracción inesperada con contraseña incorrecta' >&2; exit 1
fi
ffmpeg -v error -n -i portadores/jardin.mp4 -i "$out/ambiente.wav" -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy "$out/video.mkv"
ffmpeg -v error -n -i "$out/video.mkv" -map 0:a:0 -c:a copy "$out/audio_recuperado.wav"
steghide extract -sf "$out/audio_recuperado.wav" -xf "$out/video.txt" -p "$pass"
cmp "$out/mensaje.txt" "$out/video.txt"
ffmpeg -v error -n -i "$out/ambiente.wav" -map 0:a:0 -c:a copy -f s16le "$out/antes.pcm"
ffmpeg -v error -n -i "$out/audio_recuperado.wav" -map 0:a:0 -c:a copy -f s16le "$out/despues.pcm"
cmp "$out/antes.pcm" "$out/despues.pcm"
sha256sum "$out/mensaje.txt" "$out/video.txt" > "$out/hashes.txt"
printf 'CORRECTO: video, muestras PCM y control negativo\nResultados en %s\n' "$out"
