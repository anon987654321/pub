# encoding: utf-8
# Filesystem tool for managing files - Enhanced version
# Merged from tools/filesystem_tool.rb and backup enhanced features

require "fileutils"
require "logger"

class FileSystemTool
  def initialize
    @logger = Logger.new(STDOUT)
  end

  # Tool manager compatible execute method
  def execute(action = "read", *args)
    case action.downcase
    when "read"
      read_file(args.first)
    when "write"
      write_file(args.first, args[1])
    when "list"
      list_directory(args.first || ".")
    when "delete"
      delete_file(args.first)
    when "copy"
      copy_file(args.first, args[1])
    when "move"
      move_file(args.first, args[1])
    else
      "Unknown action: #{action}. Available: read, write, list, delete, copy, move"
    end
  end

  # Read file with enhanced error handling
  def read_file(path)
    return "File not found or not readable" unless file_accessible?(path, :readable?)

    content = File.read(path)
    log_action("read", path)
    content
  rescue => e
    handle_error("read", e)
  end

  # Write file with enhanced validation
  def write_file(path, content)
    File.write(path, content)
    log_action("write", path)
    "File written successfully"
  rescue => e
    handle_error("write", e)
  end

  # List all files and directories within the specified path
  def list_directory(path = ".")
    validate_path_exists(path)
    entries = Dir.entries(path) - ['.', '..']
    log_action("list", path)
    entries.join("\n")
  rescue => e
    handle_error("list", e)
  end

  # Delete a specified file
  def delete_file(path)
    return "File not found" unless File.exist?(path)

    File.delete(path)
    log_action("delete", path)
    "File deleted successfully"
  rescue => e
    handle_error("delete", e)
  end

  # Append content to a file
  def append_to_file(file_path, content)
    File.open(file_path, 'a') do |file|
      file.write(content)
    end
    log_action("append", file_path)
    "Content appended successfully"
  rescue => e
    handle_error("append", e)
  end

  # Create a new directory
  def create_directory(path)
    Dir.mkdir(path) unless Dir.exist?(path)
    log_action("create_dir", path)
    "Directory created successfully"
  rescue => e
    handle_error("create_dir", e)
  end

  # Copy a file from source to destination
  def copy_file(source, destination)
    validate_file_exists(source)
    FileUtils.copy(source, destination)
    log_action("copy", "#{source} -> #{destination}")
    "File copied successfully"
  rescue => e
    handle_error("copy", e)
  end

  # Move a file from source to destination
  def move_file(source, destination)
    validate_file_exists(source)
    FileUtils.mv(source, destination)
    log_action("move", "#{source} -> #{destination}")
    "File moved successfully"
  rescue => e
    handle_error("move", e)
  end

  private

  def file_accessible?(path, access_method)
    File.exist?(path) && File.public_send(access_method, path)
  end

  def log_action(action, path)
    @logger.info("#{action.capitalize} action performed on #{path}")
  end

  def handle_error(action, error)
    @logger.error("Error during #{action} action: #{error.message}")
    "Error during #{action} action: #{error.message}"
  end

  # Utility method to validate if a path exists
  def validate_path_exists(path)
    raise "Path does not exist: #{path}" unless Dir.exist?(path)
  end

  # Utility method to validate if a file exists
  def validate_file_exists(file_path)
    raise "File does not exist: #{file_path}" unless File.exist?(file_path)
  end

  # Utility method to validate if a directory exists
  def validate_directory_exists(path)
    raise "Directory does not exist: #{path}" unless Dir.exist?(path)
  end
end

# Alias for backward compatibility
FilesystemTool = FileSystemTool
