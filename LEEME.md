# Laboratorio: mensajes ocultos en medios digitales

**Asignatura:** Informática Forense. **Duración:** 120 minutos. **Modalidad:** parejas, alternando emisor y analista. **Entorno objetivo:** Debian 13, Ubuntu o Kali Linux con escritorio, instalado o en máquina virtual. Para AlmaLinux, utilizar una VM Debian/Kali para seguir exactamente esta guía.

## Material incluido

- `portadores/jardin.jpg` y `jardin.bmp`: dos formatos de una misma escena ficticia generada con IA. No son dos fotografías distintas.
- `portadores/ambiente.wav` y `tonos.wav`: audios sintéticos de 12 s, mono, PCM de 16 bits, 44.1 kHz. Reproducir a volumen moderado.
- `portadores/jardin.mp4`: desplazamiento de cámara simulado sobre la imagen, 12 s, sin audio.
- `portadores/patron.mp4`: patrón de prueba animado, 12 s, sin audio.
- `mensajes/mensaje_ejemplo.txt`: texto de muestra.
- `scripts/comprobar.sh`: genera sus propios resultados y comprueba el ciclo de inserción/extracción en los tres medios.
- `SHA256SUMS.txt`: hashes de los materiales entregados.

Los portadores se entregan SIN mensajes insertados por Steghide. Su elaboración forma parte de la práctica. El material gráfico generado puede conservar señales de procedencia del generador, distintas del mensaje de este ejercicio.

## 1. Objetivos

Ocultar un mensaje en una imagen y en audio, recuperarlo con una contraseña conocida, comprobar identidad mediante SHA-256 y distinguir ocultamiento, cifrado e integridad. Como ampliación, transportar el audio modificado dentro de un video y recuperar su mensaje.

**Escenario ficticio:** el laboratorio académico recibe archivos multimedia relacionados con el caso AULA-01. El emisor prepara un mensaje de control. El analista lo recupera y documenta el resultado sin modificar los portadores originales. Solo se usan datos ficticios.

**Herramienta principal:** Steghide. Admite JPEG, BMP, WAV y AU como portadores. No admite PNG ni MP4 directamente. FFmpeg permite conservar una pista de audio PCM en un contenedor MKV para la ampliación con video. Este ejercicio no es esteganografía sobre los fotogramas.

**Terminología:** extraer recupera la carga oculta. Si la carga está cifrada, Steghide también la descifra al proporcionar la contraseña correcta. Esta práctica no intenta romper contraseñas. El mecanismo de Steghide no equivale a la sustitución LSB elemental explicada en clase.

## 2. Instalación y preparación (15 minutos)

En una terminal de Debian, Ubuntu o Kali:

```bash
sudo apt update
sudo apt install steghide ffmpeg file unzip
steghide --version
ffmpeg -version
steghide encinfo
```

Si Ubuntu no encuentra Steghide, habilitar el repositorio Universe y repetir:

```bash
sudo add-apt-repository universe
sudo apt update
sudo apt install steghide
```

Si `add-apt-repository` no existe, instalar `software-properties-common`. No aplicar estas instrucciones de repositorios a Debian o Kali.

Descargar `Laboratorio_Esteganografia_Linux.zip`. Desde el directorio que contenga el ZIP:

```bash
unzip Laboratorio_Esteganografia_Linux.zip
cd lab_esteganografia
sha256sum -c SHA256SUMS.txt
mkdir -p trabajo recuperados evidencias
pwd
```

Los hashes deben indicar `OK` o su equivalente local. Mantener esta terminal en `lab_esteganografia` durante toda la práctica. Si se repite el laboratorio, descomprimir en otra carpeta para evitar reemplazar resultados anteriores.

Registrar nombre, equipo, fecha, distribución Linux y versión de Steghide. No usar `sudo` para insertar o extraer mensajes.

## 3. Reconocimiento y mensaje (15 minutos)

```bash
file portadores/*
steghide info portadores/jardin.jpg
steghide info portadores/ambiente.wav
```

Ante la pregunta sobre buscar información incrustada, responder `n`. Registrar la capacidad que muestra cada portador. Esta consulta no certifica ausencia de mensajes ni constituye un detector universal.

Crear el mensaje del equipo:

```bash
cat > trabajo/mensaje.txt <<'MENSAJE'
CASO AULA-01
Equipo: 01
La evidencia se verifica, no se adivina.
Codigo de control: FORENSE-2026
MENSAJE
wc -c trabajo/mensaje.txt
sha256sum trabajo/mensaje.txt > evidencias/hash_mensaje.txt
cat trabajo/mensaje.txt
```

Cada equipo cambia su número y el código de control. Mantener el mensaje por debajo de 500 bytes y confirmar que cabe en el portador, dejando margen para los datos de control de la herramienta.

Usar durante el ejercicio la contraseña didáctica `AulaForense-2026!`. Introducirla cuando la herramienta la solicite, sin comillas. La terminal no muestra caracteres al escribirla. Esta contraseña pública solo sirve para el laboratorio.

## 4. Imagen: inserción, extracción y verificación (25 minutos)

### 4.1 Crear el estegoobjeto

```bash
steghide embed -cf portadores/jardin.jpg -ef trabajo/mensaje.txt -sf trabajo/jardin_oculto.jpg
```

Introducir y confirmar la contraseña. `-cf` es el portador original, `-ef` el mensaje y `-sf` el archivo de salida. Se especifica siempre `-sf` para conservar el original.

Abrir las dos imágenes con el visor del escritorio. Comparar apariencia y registrar observaciones, sin concluir que son idénticas a nivel de bytes.

```bash
sha256sum portadores/jardin.jpg trabajo/jardin_oculto.jpg | tee evidencias/hashes_imagen.txt
steghide info trabajo/jardin_oculto.jpg
```

Esta vez responder `y` y escribir la contraseña. Registrar lo informado sobre carga, cifrado y compresión. Los hashes de los dos archivos normalmente serán diferentes: eso demuestra un cambio, no su causa.

### 4.2 Control con contraseña incorrecta

```bash
steghide extract -sf trabajo/jardin_oculto.jpg -xf recuperados/intento_incorrecto.txt
```

Escribir una contraseña incorrecta, por ejemplo `Equivocada-01`. Registrar el error. No interpretar el fallo como prueba de que no existe mensaje. Una contraseña errónea, un formato incompatible o datos alterados pueden impedir la extracción.

### 4.3 Recuperar y comprobar

```bash
steghide extract -sf trabajo/jardin_oculto.jpg -xf recuperados/mensaje_imagen.txt
cat recuperados/mensaje_imagen.txt
sha256sum trabajo/mensaje.txt recuperados/mensaje_imagen.txt
cmp trabajo/mensaje.txt recuperados/mensaje_imagen.txt && echo 'CORRECTO: mensajes identicos'
```

Introducir ahora la contraseña correcta. Los hashes del mensaje original y recuperado deben coincidir. `cmp` compara los bytes y el mensaje CORRECTO solo aparece si coinciden.

**Ampliación:** repetir con `portadores/jardin.bmp`, guardando `trabajo/jardin_oculto.bmp` y `recuperados/mensaje_bmp.txt`.

## 5. Audio: un mensaje que no se escucha (20 minutos)

```bash
steghide embed -cf portadores/ambiente.wav -ef trabajo/mensaje.txt -sf trabajo/audio_oculto.wav
steghide extract -sf trabajo/audio_oculto.wav -xf recuperados/mensaje_audio.txt
cmp trabajo/mensaje.txt recuperados/mensaje_audio.txt && echo 'CORRECTO: audio'
sha256sum portadores/ambiente.wav trabajo/audio_oculto.wav | tee evidencias/hashes_audio.txt
```

Utilizar la misma contraseña. Escuchar el original y el resultado a volumen moderado:

```bash
ffplay -nodisp -autoexit portadores/ambiente.wav
ffplay -nodisp -autoexit trabajo/audio_oculto.wav
```

Si la VM no tiene salida de sonido, continuar con la extracción y registrar esa limitación. El mensaje no es una voz: sus bytes se representan en datos de las muestras de audio. No es necesario oírlo para recuperarlo. Repetir opcionalmente con `tonos.wav`.

## 6. Video: transportar el audio sin alterarlo (20 minutos)

Aquí el mensaje permanece en la pista de audio, no en los fotogramas. Se utilizará MKV para conservar PCM. El MP4 entregado aporta únicamente el video.

### 6.1 Combinar video y audio modificado

```bash
ffmpeg -n -i portadores/jardin.mp4 -i trabajo/audio_oculto.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy trabajo/video_oculto.mkv
ffprobe -v error -show_entries stream=index,codec_name,codec_type,sample_rate,channels -of default=noprint_wrappers=1 trabajo/video_oculto.mkv
```

Comprobar que la pista de audio sea `pcm_s16le`. `-map` selecciona el video del primer archivo y el audio del segundo. `copy` conserva las pistas sin recodificarlas. `-n` evita sobrescribir un archivo existente.

### 6.2 Recuperar la pista y el mensaje

```bash
ffmpeg -n -i trabajo/video_oculto.mkv -map 0:a:0 -c:a copy recuperados/audio_desde_video.wav
steghide extract -sf recuperados/audio_desde_video.wav -xf recuperados/mensaje_video.txt
cmp trabajo/mensaje.txt recuperados/mensaje_video.txt && echo 'CORRECTO: video'
```

Usar la contraseña correcta. Abrir el MKV con un reproductor o mediante `ffplay trabajo/video_oculto.mkv`.

El hash de dos contenedores WAV puede cambiar por sus cabeceras aunque sus muestras sean iguales. Para comparar las muestras PCM:

```bash
ffmpeg -v error -n -i trabajo/audio_oculto.wav -map 0:a:0 -c:a copy -f s16le trabajo/antes.pcm
ffmpeg -v error -n -i recuperados/audio_desde_video.wav -map 0:a:0 -c:a copy -f s16le trabajo/despues.pcm
sha256sum trabajo/antes.pcm trabajo/despues.pcm
cmp trabajo/antes.pcm trabajo/despues.pcm && echo 'CORRECTO: muestras conservadas'
```

Esta comparación aplica a los audios PCM s16le del ejercicio. No convertir la pista a AAC/MP3 para el procedimiento principal: esa compresión puede destruir el mensaje. El archivo `patron.mp4` permite repetir la actividad con otro clip.

## 7. Experimento opcional: compresión con pérdida

```bash
ffmpeg -n -i trabajo/audio_oculto.wav -c:a libmp3lame -b:a 64k trabajo/audio_comprimido.mp3
ffmpeg -n -i trabajo/audio_comprimido.mp3 -c:a pcm_s16le recuperados/audio_reconvertido.wav
steghide extract -sf recuperados/audio_reconvertido.wav -xf recuperados/mensaje_tras_compresion.txt
```

Intentar con la contraseña correcta y registrar éxito o fallo. Se espera que esta transformación afecte la recuperación, pero la conclusión debe basarse en lo observado. Volver a WAV no restaura las muestras perdidas al convertir a MP3. El ensayo modifica una copia.

## 8. Intercambio entre equipos (10 minutos)

Cada equipo entrega solo su estegoobjeto, el hash SHA-256 del mensaje y, por separado, la contraseña. El receptor registra procedencia, calcula hash del archivo recibido, extrae en una carpeta propia y compara el hash del mensaje recuperado con el de referencia. No necesita el mensaje original para esa comprobación. No enviar medios mediante plataformas que los recompriman: usar ZIP o transferencia de archivos sin transformación.

## 9. Evidencias y evaluación (15 minutos)

Entregar un informe con identificación del equipo, entorno, comandos utilizados, capturas seleccionadas, tabla de resultados y conclusiones. Adjuntar los mensajes recuperados. No incluir archivos personales reales.

| Medio | Portador | Capacidad | Hash del estegoobjeto | Hash del mensaje recuperado | ¿Coincide? |
|---|---|---|---|---|---|
| Imagen | jardin.jpg | | | | |
| Audio | ambiente.wav | | | | |
| Video (audio interno) | video_oculto.mkv | No aplica al contenedor | | | |

Responder:

1. ¿Qué diferencia existe entre ocultar, extraer y descifrar?
2. ¿Qué demuestra la coincidencia de hashes de los mensajes? ¿Qué no demuestra sobre su autoría?
3. ¿Por qué la contraseña incorrecta no prueba ausencia de contenido oculto?
4. ¿En qué parte del MKV reside el mensaje?
5. ¿Por qué `-c:a copy` importa en este ejercicio?
6. ¿Qué cambia al comprimir con pérdida? Fundamentar con resultados si se realizó el ensayo.
7. ¿Por qué Steghide no debe tratarse como detector de toda forma de esteganografía?

| Criterio | Puntos | Evidencia de logro completo |
|---|---:|---|
| Instalación y preservación | 15 | Versiones, hashes iniciales y originales conservados |
| Imagen | 20 | Inserción, control negativo y recuperación correcta |
| Audio | 20 | Recuperación y comparación de bytes/hash |
| Video | 20 | PCM conservado y mensaje recuperado desde el MKV |
| Análisis e informe | 25 | Evidencias reproducibles, tabla y respuestas justificadas |
| Total | 100 | |

En cada criterio: puntaje completo si funciona y está documentado, 50% si es parcial y 0 si no hay evidencia. El docente puede distribuir el criterio de análisis según claridad y calidad de las respuestas.

## 10. Solución de problemas

| Síntoma | Acción |
|---|---|
| `command not found` | Completar la instalación y verificar `steghide --version`. |
| `could not open` o archivo no encontrado | Ejecutar `pwd` y `ls portadores`; regresar a `lab_esteganografia`. |
| Formato no soportado | Usar JPG/BMP o WAV PCM. Cambiar la extensión no convierte el archivo. |
| Portador pequeño | Reducir el texto. Comparar `wc -c` con la capacidad de `steghide info`. |
| Contraseña sin efecto | Revisar mayúsculas y signos; no aparecen caracteres al escribir. |
| No puede extraer | Verificar contraseña, archivo exacto, procedencia y transformaciones posteriores. |
| FFmpeg detecta salida existente | Elegir otro nombre o repetir en carpeta nueva. No forzar sobrescritura. |
| Fallo tras crear el MKV | Confirmar `pcm_s16le`, `-map` y `-c:a copy`; evitar recodificación. |
| Hash de WAV distinto | Comparar muestras PCM y mensaje extraído, además del contenedor. |

## 11. Comprobación previa del docente

Con las dependencias instaladas, desde `lab_esteganografia`:

```bash
bash scripts/comprobar.sh
```

El script crea un directorio nuevo por ejecución, utiliza un mensaje ficticio y una contraseña pública de prueba. Verifica JPG, BMP, ambos WAV, contraseña incorrecta y recuperación desde MKV. La opción `-p` del script automatiza únicamente esa contraseña didáctica. Para mensajes reales no introducir contraseñas sensibles en argumentos o historial.

**Estado de verificación del material:** se comprobaron los formatos y duraciones de los medios y la conservación de muestras en el recorrido WAV–MKV–WAV con FFmpeg. No se ejecutó Steghide en el entorno de creación por restricciones de instalación. Antes de clase, ejecutar el script en el Linux donde se impartirá la práctica. No se entregan resultados de extracción prevalidada.

## Referencias

- Stefan Hetzl. Manual oficial de Steghide: https://steghide.sourceforge.net/documentation/manual.pdf
- Proyecto Steghide: https://steghide.sourceforge.net/
- Debian. Paquete Steghide para Trixie: https://packages.debian.org/trixie/steghide
- FFmpeg. Documentación, selección de pistas y streamcopy: https://ffmpeg.org/ffmpeg.html

## Procedencia de los recursos

Imagen: generada con la herramienta integrada de imágenes. Prompt: “Photorealistic landscape of a fictional university botanical garden with abundant textured green foliage, brick walking paths, flowers, distant academic buildings, warm daylight. No people, no letters, no labels. Neutral carrier image for an educational digital steganography lab, rich natural texture across the whole frame, landscape 3:2.” Las versiones JPG y BMP se obtuvieron mediante conversión de formato. Audios: síntesis local de tonos y ruido a bajo nivel, sin voces reales. Videos: animación de desplazamiento sobre la imagen y patrón sintético de prueba. Todos los casos y mensajes del ejercicio son ficticios.
