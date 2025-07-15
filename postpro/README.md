Postpro.rb – Analog and Cinematic Post-Processing
Postpro.rb transforms digital images with analog and cinematic effects,
blending vintage charm with experimental lo-fi aesthetics. Powered by libvips and ruby-vips,
it creates unique variations with randomized,
layered effects for maximum variety.
Version: 13.4.27Last Modified: 2025-04-26T11:16:00ZAuthor: PubHealthcare  

Key Features

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

Installation

Install libvips (8.14.3) and Ruby (3.3+).
Install gems:gem install ruby-vips tty-prompt


Save postpro.rb to your directory.

Usage
Run:
ruby postpro.rb

Answer prompts:

Professional mode?: Analog-focused (subtle) or experimental (bold).
Random effects?: Random effects or JSON recipe.
File patterns: Images (e.g., **/*.{jpg,png}).
Variations: 1–5 variants.
Effects per variant: 3–5 (professional) or 5–8 (experimental).
Save recipe?: Save effect settings as JSON.
Optimize for web?: 256-color palette for smaller files.

Outputs: image_processed_vX_YYYYMMDDHHMMSS_XXXX.ext.
Effects

Core Analog: film_grain, film_scratches, film_stock_emulation (Kodak Portra, Fuji Velvia).
Cinematic: golden_hour_glow, bloom_effect, teal_and_orange, cinemascope_bars.
Lo-Fi: vhs_artifact, glitch, pixel_sorting, static_noise.
New: emulsion_layering, temporal_wear, spectral_color_drift.

Edge Cases

Invalid Files: Skipped with clear errors (e.g., "File does not exist or is not readable").
Large Images: Processed, but monitor postpro.log for memory usage.
Malformed JSON: Skipped with error (e.g., "Invalid JSON recipe").
Grayscale Images: Converted to RGB automatically.
Zero-Band Images: Skipped with error (e.g., "Image has zero bands").

Notes

Logs: postpro.log includes memory usage and detailed traces.
Recipes: Saved as recipe_YYYYMMDDHHMMSS_XXXX.json to avoid overwrites.
Web Optimization: Uses cached 256-color palette for efficiency.
Fixed Issues:
Zero-band image crashes.
Memory leaks in noise cache.
Band mismatches in effects.
Recipe file collisions.
Performance bottlenecks (e.g., redundant computations).



Example
Process three variants of all JPEGs with random effects:
ruby postpro.rb
# Professional mode? Yes
# Random effects? Yes
# File patterns: **/*.jpg
# Variations: 3
# Effects per variant: 4
# Save recipe? Yes
# Optimize for web? Yes

License
MIT License. See LICENSE for details.