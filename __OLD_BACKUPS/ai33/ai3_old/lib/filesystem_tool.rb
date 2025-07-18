# frozen_string_literal: true

# filesystem_tool.rb - Enhanced Filesystem Tool

class FilesystemTool
  def initialize; end

  # List all files and directories within the specified path
  def list_directory(path)
    validate_path_exists(path)
    Dir.entries(path) - ['.', '..']
  end

  # Read the contents of a file
  def read_file(file_path)
    validate_file_exists(file_path)
    File.read(file_path)
  end

  # Write content to a file, create file if it does not exist
  def write_file(file_path, content)
    File.write(file_path, content)
  end

  # Append content to a file
  def append_to_file(file_path, content)
    File.open(file_path, 'a') do |file|
      file.write(content)
    end
  end

  # Delete a specified file
  def delete_file(file_path)
    validate_file_exists(file_path)
    File.delete(file_path)
  end

  # Create a new directory
  def create_directory(path)
    Dir.mkdir(path) unless Dir.exist?(path)
  end

  # Delete a specified directory if it is empty
  def delete_directory(path)
    validate_directory_exists(path)
    Dir.rmdir(path)
  end

  # Recursively delete a directory and its contents
  def delete_directory_recursive(path)
    validate_directory_exists(path)
    FileUtils.rm_rf(path)
  end

  # Copy a file from source to destination
  def copy_file(source, destination)
    validate_file_exists(source)
    FileUtils.copy(source, destination)
  end

  # Move a file from source to destination
  def move_file(source, destination)
    validate_file_exists(source)
    FileUtils.mv(source, destination)
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
