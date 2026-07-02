# Verdant Shader

Ein kleines Minecraft-Shaderpack fuer Minecraft 1.21.1 mit NeoForge plus Iris/Oculus-kompatiblem Shader-Loader.

## Installation

1. Kopiere diesen Ordner oder eine ZIP dieses Ordners in den `shaderpacks`-Ordner deiner Minecraft-Instanz.
2. Starte Minecraft 1.21.1 mit NeoForge und einem Shader-Loader wie Iris/Oculus.
3. Waehle `Verdant Shader` im Shader-Menue aus.

## Enthaltene Effekte

- GLSL-330-Shader nach der Iris-Tutorial-Pipeline
- G-Buffer fuer Farbe, Lightmap und Normalen
- Deferred-Beleuchtung mit Blocklicht, Himmelslicht, Sonnenlicht und getoenten Schatten
- leichte Specular-Highlights und Rim-Light
- Shadow-Map-Pass mit Verzerrung fuer schaerfere Nahbereichsschatten
- dramatisch geschichtete Sky-Wolken im Postpass, inspiriert von realistischen Skybox-Resourcepacks
- optional weiter stilisierte Vanilla-Wolken, falls `gbuffers_clouds` vom Loader gerendert wird
- erzwingt `clouds=fancy`, damit der Cloud-Pass auch bei deaktivierten Vanilla-Wolken laeuft
- leichter Bloom fuer helle Wolken, Himmel und Highlights
- Tiefenbasierter Fog mit dezenter Horizont-Atmosphaere
- einstellbares Colorgrading ueber `STYLE_STRENGTH`
- deutsche und englische Beschreibungen fuer die Shader-Einstellungen
- Gamma-Korrektur im Final-Pass
