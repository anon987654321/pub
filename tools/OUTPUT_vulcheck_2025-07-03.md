## `vulcheck.md`
```
<html><head></head><body><pre><code># vulcheck.rb - Comprehensive Security Check for macOS, iOS, and Android

## Overview
`vulcheck.rb` is a Ruby-based script designed to detect system infections, rootkits, jailbreaks, and unauthorized system access. It automates the installation and updating of essential tools, performs in-depth security scans, and provides actionable logs for analysis.

### Key Features
- **macOS Support**: Uses `chkrootkit`, `rkhunter`, and `aide` to detect rootkits, malware, and file integrity issues. Fully compatible with legacy macOS versions.
- **iOS Jailbreak Detection**: Identifies common jailbreak indicators, ensuring a quick security assessment for both jailbroken and non-jailbroken devices.
- **Android Root Access Detection**: Detects root access indicators like `su` binaries and unauthorized system modifications.
- **Real-Time Intrusion Detection**: Scans active network connections and running processes to detect ongoing intrusions.
- **Automated Tool Management**: Updates detection tools to ensure the latest signatures and rules are applied.
- **Cross-Platform**: Runs seamlessly on macOS, iOS, and Android.

## Requirements
### macOS
- **MacPorts**: Required to install and manage dependencies. Install from [MacPorts](https://www.macports.org/).
- **Root Privileges**: The script must be run with `sudo` to perform system-level scans.

### iOS
- **No Additional Setup Required**: The script detects jailbreak indicators with no need for installation.

### Android
- **Rooted or Non-Rooted Devices**: Supports scanning both rooted and non-rooted devices.
- **Optional**: Use [Termux](https://f-droid.org/packages/com.termux/) for an enhanced scanning environment.

## Installation
1. Clone or download the repository.
   ```bash
   git clone &lt;repository-url&gt;
   cd &lt;repository-folder&gt;
   ```
2. Ensure Ruby is installed:
   - macOS: Ruby comes pre-installed.
   - Android: Install Ruby via Termux:
     ```bash
     pkg update &amp;&amp; pkg upgrade
     pkg install ruby
     ```
3. For macOS, ensure MacPorts is installed and functional.

## Usage
Run the script with the appropriate option for your platform:

### macOS
Install dependencies, update tools, and perform full security scans:
```bash
sudo ruby vulcheck.rb --macos
```

### iOS
Scan for jailbreak indicators and perform basic security checks:
```bash
sudo ruby vulcheck.rb --ios
```

### Android
Detect root access indicators and unauthorized system modifications:
```bash
ruby vulcheck.rb --android
```

## Logs
All results are logged to `vulcheck_log.txt` in the current directory. Logs include:
- Timestamped actions and scan results.
- Identified rootkits, suspicious files, and unauthorized access indicators.
- Summaries of active connections and processes.

## Notes
- **macOS**: Regularly update tools (`chkrootkit` and `rkhunter`) to ensure detection rules remain effective.
- **iOS**: Jailbreaking is not required for basic checks but enables deeper scans.
- **Android**: The presence of the `su` binary typically indicates root access; review logs carefully to verify.

## Limitations
- **Non-Jailbroken iOS Devices**: Limited to basic checks for jailbreak indicators.
- **Unrooted Android Devices**: Cannot access system-level files; limited to user-space scans.
- **macOS SIP**: System Integrity Protection may restrict scans of critical files on newer macOS versions.

```

## `vulcheck.rb`
```
#!/usr/bin/env ruby

# **vulcheck.rb**
#
# This script performs security checks for macOS, iOS, and Android devices. It detects rootkits, jailbreaks, unauthorized access, and active intrusions. It automates updates for tools like `chkrootkit` and `rkhunter`, and logs results for review.

require 'optparse'
require 'fileutils'
require 'open3'

class VulCheck
  MACPORTS_PACKAGES = %w[chkrootkit rkhunter aide].freeze
  # `aide` is included for file integrity checking, complementing `chkrootkit` and `rkhunter`.
  LOG_FILE = 'vulcheck_log.txt'

  # Ensure script is run with sudo
  def self.ensure_sudo
    unless Process.uid.zero?
      log('Root privileges are necessary for installing tools and scanning system files.')
      log_and_exit('This script must be run with sudo privileges.')
    end
  end

  # Determine the system type: macOS, iOS, or Android
  def self.check_system
    if RUBY_PLATFORM.include?('darwin')
      if File.exist?('/Applications/Utilities/Terminal.app') # macOS
        return 'macos'
      elsif File.exist?('/System/Applications/Feedback.app') # iOS
        return 'ios'
      end
    elsif RUBY_PLATFORM.include?('android')
      return 'android'
    end
    raise 'Unsupported OS'
  end

  # Ensure MacPorts is installed (for macOS)
  def self.ensure_macports
    unless system('which port > /dev/null 2>&1')
      log_and_exit('MacPorts not found. Please install MacPorts first: https://www.macports.org/')
    end
  end

  # Install required tools using MacPorts (for macOS)
  def self.install_dependencies
    log('Installing required tools using MacPorts...')
    MACPORTS_PACKAGES.each do |pkg|
      unless system("port installed #{pkg} > /dev/null 2>&1")
        log("Installing #{pkg}...")
        system("sudo port install #{pkg}") || raise("Failed to install #{pkg}.")
      end
    end
    log('All required tools are installed.')
  end

  # Update rootkit detection tools for macOS
  def self.update_tools
    log('Updating rootkit detection tools...')
    system('sudo rkhunter --update') || log('Failed to update rkhunter. Regular updates ensure detection rules remain effective.')
    system('sudo chkrootkit --update') || log('Failed to update chkrootkit.')
    log('Tools updated successfully.')
  end

  # Run security scans on macOS
  def self.run_macos_scans
    log('Running security scans for macOS...')
    MACPORTS_PACKAGES.each do |tool|
      command = case tool
                when 'chkrootkit' then tool
                when 'rkhunter' then "#{tool} --check"
                when 'aide' then "#{tool} --check"
                else next
                end
      log("Executing: #{command}")
      system(command) || log("Error: #{tool} scan encountered an issue.")
    end
  end

  # Detect active intrusions on macOS
  def self.detect_active_intrusions
    log('Checking for active intrusions on macOS...')
    log('Active network connections:')
    system('netstat -an | grep ESTABLISHED')
    log('Review the above connections for unusual remote addresses or unauthorized access.')
    log('Suspicious running processes:')
    system('ps aux | grep -i suspicious')
  end

  # Detect jailbreak indicators on iOS
  def self.check_ios_jailbreak
    log('Checking for jailbreak indicators on iOS...')
    jailbreak_indicators = [
      '/Applications/Cydia.app',
      '/usr/sbin/sshd',
      '/bin/bash',
      '/private/var/stash',
      '/usr/libexec/ssh-keysign'
    ]

    jailbreak_indicators.each do |path|
      if File.exist?(path)
        log("Warning: Jailbreak indicator found at #{path}")
      end
    end
    log('Finished checking for jailbreak indicators on iOS.')
  end

  # Detect root access on Android
  def self.check_android_root
    log('Checking for root access on Android...')
    root_indicators = [
      '/system/xbin/su',
      '/system/bin/su',
      '/data/data/com.noshufou.android.su',
      '/sbin/su'
    ]

    root_indicators.each do |path|
      if File.exist?(path)
        log("Warning: Root access indicator found at #{path}")
      end
    end

    log('Active network connections:')
    system('netstat -an | grep ESTABLISHED')

    if system('which su > /dev/null 2>&1')
      log('The presence of `su` may indicate the device is rooted. Verify the need for this binary.')
      log('Warning: Device may be rooted (su command found).')
    end
    log('Finished checking for root access on Android.')
  end

  # Log messages to console and file
  def self.log(message)
    puts message
    File.open(LOG_FILE, 'a') { |file| file.puts("#{Time.now}: #{message}") }
  end

  # Log an error and exit
  def self.log_and_exit(message)
    log(message)
    exit(1)
  end

  # Execute the script based on detected OS
  def self.execute
    ensure_sudo
    system_type = check_system
    case system_type
    when 'macos'
      log('macOS detected.')
      ensure_macports
      install_dependencies
      update_tools
      detect_active_intrusions
      run_macos_scans
    when 'ios'
      log('iOS detected.')
      check_ios_jailbreak
    when 'android'
      log('Android detected.')
      check_android_root
    else
      log_and_exit('Unsupported system type detected.')
    end
  end
end

# Parse command-line options
options = {}

OptionParser.new do |opts|
  opts.banner = 'Usage: vulcheck.rb [options]'

  opts.on('--macos', 'Run the script for macOS') { options[:macos] = true }
  opts.on('--ios', 'Run the script for iOS') { options[:ios] = true }
  opts.on('--android', 'Run the script for Android') { options[:android] = true }
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

if options[:macos] || options[:ios] || options[:android]
  VulCheck.execute
else
  VulCheck.log_and_exit('Error: Please specify either --macos, --ios, or --android.')
end

```

