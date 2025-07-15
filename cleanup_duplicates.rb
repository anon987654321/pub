#!/usr/bin/env ruby

# Cleanup duplicate files identified in the repository analysis

require 'json'
require 'fileutils'

class DuplicateFileCleanup
  def initialize
    @report_file = 'cleanup_report.json'
    @duplicate_files = []
    @safe_to_remove = []
    @review_required = []
  end

  def load_analysis
    return unless File.exist?(@report_file)
    
    report = JSON.parse(File.read(@report_file))
    @duplicate_files = report['analysis']['duplicate_files'] || []
    puts "📊 Found #{@duplicate_files.length} duplicate file pairs"
  end

  def analyze_duplicates
    puts "\n🔍 Analyzing duplicate files for safe removal..."
    
    @duplicate_files.each do |duplicate_pair|
      file1, file2 = duplicate_pair
      
      # Check if files are in __delete directories (safe to remove)
      if file1.include?('__delete') && !file2.include?('__delete')
        @safe_to_remove << file1
        puts "✅ Safe to remove: #{file1} (in __delete directory)"
      elsif file2.include?('__delete') && !file1.include?('__delete')
        @safe_to_remove << file2
        puts "✅ Safe to remove: #{file2} (in __delete directory)"
      elsif file1.include?('__delete') && file2.include?('__delete')
        # Both in __delete, remove the one with longer path
        if file1.length > file2.length
          @safe_to_remove << file1
          puts "✅ Safe to remove: #{file1} (longer path in __delete)"
        else
          @safe_to_remove << file2
          puts "✅ Safe to remove: #{file2} (longer path in __delete)"
        end
      elsif file1.include?('postpro/__cameras') || file2.include?('postpro/__cameras')
        # Camera files are likely duplicates of a template
        camera_file = file1.include?('postpro/__cameras') ? file1 : file2
        @safe_to_remove << camera_file
        puts "✅ Safe to remove: #{camera_file} (camera template duplicate)"
      else
        @review_required << duplicate_pair
        puts "⚠️  Requires review: #{file1} vs #{file2}"
      end
    end
    
    puts "\n📋 Summary:"
    puts "  - Safe to remove: #{@safe_to_remove.length} files"
    puts "  - Requires review: #{@review_required.length} pairs"
  end

  def cleanup_safe_files
    puts "\n🧹 Cleaning up safe duplicate files..."
    
    removed_count = 0
    total_size_saved = 0
    
    @safe_to_remove.each do |file|
      if File.exist?(file)
        file_size = File.size(file)
        File.delete(file)
        removed_count += 1
        total_size_saved += file_size
        puts "🗑️  Removed: #{file} (#{file_size} bytes)"
      else
        puts "⚠️  Already removed: #{file}"
      end
    end
    
    puts "\n✅ Cleanup complete:"
    puts "  - Files removed: #{removed_count}"
    puts "  - Total size saved: #{format_bytes(total_size_saved)}"
  end

  def format_bytes(bytes)
    units = ['B', 'KB', 'MB', 'GB']
    unit_index = 0
    size = bytes.to_f
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(2)} #{units[unit_index]}"
  end

  def generate_review_report
    return if @review_required.empty?
    
    puts "\n📝 Generating review report for remaining duplicates..."
    
    review_content = <<~REVIEW
      # Duplicate Files Requiring Manual Review

      The following file pairs are duplicates but require manual review before removal:

      #{@review_required.map.with_index { |pair, index| 
        "## Duplicate Pair #{index + 1}\n" +
        "- **File 1**: `#{pair[0]}`\n" +
        "- **File 2**: `#{pair[1]}`\n" +
        "- **Action Required**: Compare files and remove the less appropriate one\n"
      }.join("\n")}

      ## Review Guidelines

      1. **Compare file contents** to ensure they are truly identical
      2. **Check file usage** in the codebase to determine which is actively used
      3. **Consider file location** - prefer files in main directories over subdirectories
      4. **Preserve the most recent** or most complete version
      5. **Update references** if needed after removal

      ## After Review

      Remove duplicate files manually and update this report.
    REVIEW
    
    File.write('DUPLICATE_REVIEW.md', review_content)
    puts "✅ Created DUPLICATE_REVIEW.md with #{@review_required.length} pairs for manual review"
  end

  def run
    puts "🚀 Starting duplicate file cleanup..."
    puts "=" * 50
    
    load_analysis
    analyze_duplicates
    cleanup_safe_files
    generate_review_report
    
    puts "\n" + "=" * 50
    puts "✅ Duplicate cleanup complete!"
    puts "📋 Review DUPLICATE_REVIEW.md for remaining duplicates"
  end
end

# Run the duplicate cleanup
if __FILE__ == $0
  cleanup = DuplicateFileCleanup.new
  cleanup.run
end