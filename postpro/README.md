<<<<<<< HEAD
# Postpro.rb – Analog and Cinematic Post-Processing
=======
Postpro.rb – Analog and Cinematic Post-Processing
Postpro.rb transforms digital images with analog and cinematic effects,
blending vintage charm with experimental lo-fi aesthetics. Powered by libvips and ruby-vips,
it creates unique variations with randomized,
layered effects for maximum variety.
Version: 13.4.27Last Modified: 2025-04-26T11:16:00ZAuthor: PubHealthcare  
>>>>>>> refs/remotes/origin/main

**Version:** 12.9.0  
**Last Modified:** 2025-02-03T00:00:00Z  
**Author:** PubHealthcare  

<<<<<<< HEAD
---
=======
Consolidated Effects: 30 streamlined effects (e.g., optical_flare, tone_grading, vhs_artifact) in a unified format, no scanlines.
Enhanced Analogness: Emulsion layering, temporal wear, spectral color drift for realistic film effects.
True Random Layering: 3–5 effects (professional,
intensity 0.1–0.4) or 5–8 (experimental,
intensity 0.2–0.6),
mood-based (warm,
cool,
neutral).
Efficiency: Effect batching, lazy evaluation, capped noise cache, cached web palette.
Robustness: Handles zero-band images, band mismatches, file permissions, and recipe collisions.
CLI Workflow: Interactive prompts with clear error messages for mode,
files,
variations,
web optimization (256-color palette).
Debugging: Memory usage logging in postpro.log.
>>>>>>> refs/remotes/origin/main

Postpro.rb is an **interactive CLI** tool that applies analog and cinematic effects to images using [libvips](https://libvips.github.io/libvips/) via [ruby-vips](https://github.com/libvips/ruby-vips). It allows **recursive batch processing** of entire folders, layering multiple transformations—such as film grain, blur, halation, VHS-style degrade, and more—for a fully customized look.

---

## Key Features

1. **Analog & Retro**  
   - **Film Grain & Vignetting**: Classic film texture  
   - **VHS Degrade & Light Leaks**: 80s/90s analog feel  

2. **Cinematic Looks**  
   - **Bloom & Halation**: Dreamy highlight glows  
   - **Teal-and-Orange & Day-for-Night**: Hollywood-grade color grading  
   - **Anamorphic Simulation**: Widescreen lens flares  

3. **Layered Processing**  
   - Combine multiple effects (grain, hue shifts, color fade, etc.) in one pass  
   - Fine-tune each effect’s intensity  

4. **Interactive CLI**  
   - Choose random or custom JSON recipes  
   - Specify file patterns (e.g., `**/*.jpg`) to batch-process recursively  

5. **High Speed & Low Memory**  
   - Built on libvips, known for its efficient, fast performance  

---

## Example Interactive Flow

```bash
$ ruby postpro.rb
Apply a random combination of effects? (Y/n): y
Enter file patterns (default: **/*.jpg, **/*.jpeg, **/*.png, **/*.webp): images/**/*.jpg
How many variations per image? (default: 3): 4

Starting image processing...
Processing file: images/pic1.jpg
Applied effect: film_grain (intensity: 1.2)
Applied effect: teal_and_orange (intensity: 1.0)
Applied effect: bloom_effect (intensity: 1.5)
Saved variation 1 as images/pic1_processed_v1_20250203151145.jpg
Saved variation 2 as images/pic1_processed_v2_20250203151145.jpg
Saved variation 3 as images/pic1_processed_v3_20250203151145.jpg
Saved variation 4 as images/pic1_processed_v4_20250203151145.jpg
Processing completed.
```

- **Random Effects** or **Load a JSON recipe**  
- **Recursive** matching: `images/**/*.{jpg,png}`  
- **Multiple Variations**: e.g., 4 unique outputs per file  

---

## Installation

1. **Install libvips**  
   - **OpenBSD**: `pkg_add vips`  
   - **Ubuntu/Debian**: `apt-get install libvips`  
   - **macOS**: `brew install vips`

2. **Install Ruby Gems**  
   ```bash
   gem install --user-install ruby-vips tty-prompt
   ```

### OpenBSD Tips

On **OpenBSD**, ensure **libvips** is recognized:
```sh
doas pkg_add -U vips
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```
Confirm that **ruby-vips** is installed and the `.so` is in your `LD_LIBRARY_PATH`.

---

## JSON Recipe Usage

Create a JSON file (e.g., `myrecipe.json`):

```json
{
  "film_grain": 1.0,
  "day_for_night": 0.8,
  "bloom_effect": 1.2
}
```

Then, when prompted, enter the filename to **apply that exact recipe**.

---

## Advanced Notes

- **Multiple Effects**: Stack **grain, hue shift, vhs_degrade, halation** in one pass for unique combos.  
- **Performance**: libvips processes large images quickly with minimal memory.  
- **Cinematic Controls**: Adjust intensities to preserve skin tones or push stylized extremes.

<<<<<<< HEAD
=======
License
MIT License. See LICENSE for details.
>>>>>>> refs/remotes/origin/main
