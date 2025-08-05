# encoding: utf-8
# Filesystem tool for managing files

require "fileutils"
require "logger"

class FilesystemTool
  def initialize
    @logger = Logger.new(STDOUT)
  end

  def read_file(path)
    return "File not found or not readable" unless file_accessible?(path, :readable?)

    content = File.read(path)
    log_action("read", path)
    content
  rescue => e
    handle_error("read", e)
  end

  def write_file(path, content)
    # For new files, check if directory is writable instead
    dir = File.dirname(path)
    return "Permission denied" unless File.exist?(dir) && File.writable?(dir)

    File.open(path, 'w') {|f| f.write(content)}
    log_action("write", path)
    "File written successfully"
  rescue => e
    handle_error("write", e)
  end

  def delete_file(path)
    return "File not found" unless File.exist?(path)

    FileUtils.rm(path)
    log_action("delete", path)
    "File deleted successfully"
  rescue => e
    handle_error("delete", e)
  end

  # Additional methods from backup for enhanced functionality
  def list_directory(path)
    validate_path_exists(path)
    Dir.entries(path) - ['.', '..']
  rescue => e
    handle_error("list_directory", e)
  end

  def append_to_file(file_path, content)
    File.open(file_path, 'a') do |file|
      file.write(content)
    end
    log_action("append", file_path)
    "Content appended successfully"
  rescue => e
    handle_error("append", e)
  end

  def create_directory(path)
    Dir.mkdir(path) unless Dir.exist?(path)
    log_action("create_directory", path)
    "Directory created successfully"
  rescue => e
    handle_error("create_directory", e)
  end

  def delete_directory(path)
    validate_directory_exists(path)
    Dir.rmdir(path)
    log_action("delete_directory", path)
    "Directory deleted successfully"
  rescue => e
    handle_error("delete_directory", e)
  end

  def delete_directory_recursive(path)
    validate_directory_exists(path)
    require 'fileutils'
    FileUtils.rm_rf(path)
    log_action("delete_directory_recursive", path)
    "Directory recursively deleted successfully"
  rescue => e
    handle_error("delete_directory_recursive", e)
  end

  def copy_file(source, destination)
    validate_file_exists(source)
    require 'fileutils'
    FileUtils.copy(source, destination)
    log_action("copy_file", "#{source} -> #{destination}")
    "File copied successfully"
  rescue => e
    handle_error("copy_file", e)
  end

  def move_file(source, destination)
    validate_file_exists(source)
    require 'fileutils'
    FileUtils.mv(source, destination)
    log_action("move_file", "#{source} -> #{destination}")
    "File moved successfully"
  rescue => e
    handle_error("move_file", e)
  end

  # Compatibility methods for tools/ interface
  def read(file_path)
    read_file(file_path)
  rescue => e
    @logger.error("File not found: #{file_path} – #{e.message}")
    nil
  end

  def write(file_path, content)
    write_file(file_path, content)
    @logger.info("Wrote content to #{file_path}")
    true
  rescue => e
    @logger.error("Error writing to file #{file_path}: #{e.message}")
    false
  end

  # Execute method provides a unified interface for tool manager
  def execute(action = "read", *args)
    case action.downcase
    when "read"
      read(args.first)
    when "write"
      write(args.first, args[1])
    else
      "Unknown action"
    end
  end

  private

  # Validation methods from backup
  def validate_path_exists(path)
    raise "Path does not exist: #{path}" unless Dir.exist?(path)
  end

  def validate_file_exists(file_path)
    raise "File does not exist: #{file_path}" unless File.exist?(file_path)
  end

  def validate_directory_exists(path)
    raise "Directory does not exist: #{path}" unless Dir.exist?(path)
  end

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
end
