# Prompts

1. **ANALYZE**

   - Operate in **QUIET MODE** (no summarizing or explaining).
   - Always do a recursive file tree listing first before entering a new archive.
   - Then proceed to do the deepest possible review of those files, excluding `tmp/`, `.git`, and `.bundler` folders. Perform a thorough and detailed analysis.
   - Start with `README.md` and `lib/` if available.
   - Automatically proceed to the next file/repo/task without asking for my permission to continue.

2. **IMPROVE**

   - Operate in **QUIET MODE** (no summarizing or explaining).
   - Always do a recursive file tree listing first before entering a new archive.
   - Do not delete any existing code or comments (unless redundant). Ensure all is retained; maintain 100% project integrity.
   - Iteratively flesh out with pseudo code and embellish until production-ready, and then refine and streamline iteratively until the code can't be anymore improved. Keep an eye out for bugs, syntax errors, code smells, logical oddities and poor/missing comments.
   - Split large files and tasks into smaller, manageable units.

   - Use clear, concise, ELI5-style English, adhering to Strunk & White's guidelines.
   - Save all the latest improvements and consolidate with the original code and archive into *NEW_<iteration>.tgz, while remaining quiet.
   - If asked to show the code in a code block, be sure to wrap the master block in four backticks to prevent display issues. If additional blocks are required sequentially, be sure to only post the code and do not include any intro/utro sentences.

3. **STYLE GUIDELINES**

   - Use double quotes, two-space indents, and wrap code blocks in four backticks.

   - **HTML/CSS**
     - Write 100% semantic HTML5 with a mobile-first, ultra-minimalistic approach.
     - Sort SCSS rules by feature and properties alphabetically. Target elements directly; avoid unnecessary class names. Use underscores instead of dashes if needed.
     - Prefer modern CSS methods (flexbox, grid layouts) over outdated techniques (floats, clears, absolute positioning, box-shadows).

   - **RUBY ON RAILS**
     - Use Rails tag helpers (with I18n) instead of standard HTML tags, e.g., `<%= tag.p t("hello_world") %>`. Update corresponding YAML files for English and Norwegian.
     - Break views into partials where feasible.
     - Leverage the latest features from the Rails Edge Guides, Turbo Handbook, Stimulus Handbook, StimulusReflex, and Stimulus-Components.com.
     - Consolidate changes into a Zsh installer script, grouped by feature and chronology, with each section separated by `# -- <GIT COMMIT MESSAGE IN UPPERCASE> --\n\n`.

4. **RESEARCH**

   - Spend 10 iterations web searching for related keywords and combinations of keywords to find improved code. Use resources like Ar5iv.org, Rails Edge Guides, GoRails.com.
   - Spend another 10 iterations embellishing, refining, and streamlining based on findings.


