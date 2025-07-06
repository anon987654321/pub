# Prompts

## General Instructions

1. **Quiet Mode:**  
   - Operate silently without summarizing or explaining. Automatically proceed from one task to the next without asking for permission.

2. **Preserve Integrity:**  
   - Maintain 100% project integrity. Do not delete or truncate content unless explicitly marked redundant. Ensure all content, including blank lines, is preserved.

3. **File Structure & Thorough Analysis:**  
   - Create a directory tree after extracting compressed archives.  
   - Conduct an in-depth review of every line in every file (starting with `README.md` if present), excluding temporary files, vendor files, and dotfiles.

## Code Improvement

1. **Flesh Out Pseudo Code:**  
   - Calculate how many iterations are needed to fully flesh out missing features (production-ready). Then proceed automatically with that exact amount of iterations; show only the full and final iteration. Aim for real logic and concrete functionalities as opposed to filler code and placeholders.

2. **Enhance & Optimize:**  
   - Refine and streamline (without deleting important code or comments) iteratively until production-ready. Fix bugs, syntax errors, logical oddities, and lacking comments or documentation.
   - Use double quotes and two-space indents. Wrap master code blocks in four backticks.
   - Deliver: Confirm if output should be codeblock or Zsh installer script, with necessary shell commands, the files themselves created with cat and HereDoc, and Git commits; organized chronologically and by feature set.

## Style Guidelines

1. **General:**  
   - Use double quotes instead of single quotes. Indent with two spaces instead of tabs. Wrap master code blocks in four backticks to prevent display issues.
   - Use 

2. **HTML/CSS:** 
   - Must be 100% semantic, ultra-minimalistic, and modern HTML5 (no divitis).
   - Write an enhanced mobile-first application SCSS (with desktop rules in a separate section at the bottom).
   - Misc: 1) Use underscores instead of dashes for class names. 2) Sort CSS rules by feature, and sort CSS properties alphabetically. 2) Avoid targeting unnecessary class names directly, i.e., `footer > a` instead of `.footer  a.footer-link`.
   - Choose flexbox, grid layouts, and media queries over outdated methods like floats, clears, absolute positioning, etc.

3. **Ruby on Rails:**  
   - Analyze or create `README.md` in brief, clear, ELI5-style English that adheres to Strunk & White’s guidelines.
   - Use Rails tag helpers (e.g., `<%= tag.p t("hello_world") %>`) instead of standard HTML tags.
   - Break views into partials where feasible.
   - Leverage the latest documentation from Hotwire (Turbo and Stimulus.js), StimulusReflex, and Stimulus-Components.com.
   - Create comments and update I18n YAML files for English and Norwegian translations.

## Research Guidelines

1. **Browser Research:**  
   - Conduct 20-30 searches on [ar5iv.org](https://ar5iv.org) for relevant research.  
   - Summarize your findings in a bullet-point list.

