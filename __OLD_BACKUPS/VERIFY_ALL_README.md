# OpenBSD Infrastructure Verification Script

## Overview

`verify_all.sh` is a comprehensive verification script designed to check the status and health of all Rails applications and OpenBSD infrastructure components described in this repository.

## Features

The script performs the following checks:

### 1. System Health Checks
- **OpenBSD Services**: PostgreSQL, Redis, httpd, relayd
- **Firewall**: pf firewall status and rules
- **System Resources**: Disk space and memory usage

### 2. SSL Certificate Verification
- Checks SSL certificates for all configured domains
- Validates certificate expiration dates
- Warns about certificates expiring within 30 days
- Alerts for certificates expiring within 7 days

### 3. DNS Resolution
- Tests DNS resolution for all configured domains
- Validates that domains resolve correctly
- Provides suggestions for DNS configuration issues

### 4. Rails Application Checks
- Verifies application directory structure
- Checks for required files (Gemfile, package.json, database.yml)
- Validates database connectivity
- Monitors Falcon server status for each application
- Checks environment configuration files

### 5. Infrastructure Verification
- Validates shared utility scripts
- Checks log directory accessibility
- Monitors system resource usage
- Verifies backup system functionality

### 6. Feature-Specific Checks
- **Ruby Version**: Validates Ruby 3.3.0 installation
- **Node.js Version**: Validates Node.js 20 installation
- **Falcon Gem**: Checks for Falcon web server gem
- **Critical Directories**: Ensures required directories are accessible

### 7. Network and Security
- **Port Monitoring**: Checks if required ports (22, 53, 80, 443) are listening
- **Firewall Rules**: Validates pf firewall configuration
- **SSH Protection**: Checks for SSH brute force protection
- **HTTP Responses**: Tests HTTP response from local services

## Usage

### Basic Usage
```bash
./verify_all.sh
```

### Command Line Options
```bash
./verify_all.sh [OPTIONS]

OPTIONS:
    --verbose   Show detailed output for all checks
    --quiet     Only show errors and warnings
    --json      Output results in JSON format
    --help      Show help message
```

### Examples
```bash
# Run all checks with standard output
./verify_all.sh

# Run with detailed output
./verify_all.sh --verbose

# Generate JSON report
./verify_all.sh --json > report.json

# Run quietly (only errors and warnings)
./verify_all.sh --quiet
```

## Infrastructure Configuration

The script is configured to work with the following infrastructure setup:

### Applications
- **brgen**: Multi-tenant social/marketplace platform
- **amber**: AI-enhanced fashion social network
- **pubattorney**: Legal service platform
- **bsdports**: Software package sharing platform
- **hjerterom**: Food redistribution platform
- **privcam**: Private video sharing platform
- **blognet**: Blog sharing platform

### Domains
The script checks 56 domains across:
- **Nordic Region**: .no, .is, .dk, .se, .fi domains
- **British Isles**: .uk domains
- **Continental Europe**: .nl, .be, .ch, .li, .de, .fr, .it, .pt, .pl domains
- **North America**: .us, .com domains
- **Specialized Applications**: Various application-specific domains

### Technical Stack
- **OpenBSD**: 7.8
- **Rails**: 8.0.0
- **Ruby**: 3.3.0
- **Node.js**: 20
- **Database**: PostgreSQL
- **Cache**: Redis
- **Web Server**: Falcon
- **Load Balancer**: relayd
- **HTTP Server**: httpd
- **SSL**: acme-client

## Output Formats

### Standard Output
The script provides color-coded output:
- **🟢 GREEN**: Passed checks
- **🟡 YELLOW**: Warnings
- **🔴 RED**: Failed checks
- **🔵 BLUE**: Informational messages

### JSON Output
When using `--json` flag, the script outputs structured JSON:
```json
{
  "timestamp": "2025-01-21T12:00:00Z",
  "summary": {
    "total_checks": 51,
    "passed": 45,
    "failed": 3,
    "warnings": 3,
    "success_rate": "88.24%"
  },
  "status": "ISSUES_FOUND",
  "log_file": "/tmp/verify_all_20250121_120000.log"
}
```

## Error Handling

The script includes comprehensive error handling:
- **Graceful Degradation**: Continues checking even if some commands fail
- **Command Availability**: Checks for command availability before execution
- **Timeout Protection**: Limits DNS and SSL checks to prevent hanging
- **Detailed Logging**: All checks are logged with timestamps

## Performance Considerations

To ensure reasonable execution time:
- **DNS checks**: Limited to first 10 domains
- **SSL checks**: Limited to first 10 domains
- **Timeout protection**: Prevents hanging on network operations
- **Efficient commands**: Uses lightweight commands where possible

## Exit Codes

- **0**: All checks passed (no failures)
- **1**: One or more checks failed

## Log Files

Detailed logs are created in `/tmp/` with timestamps:
- **Log format**: `verify_all_YYYYMMDD_HHMMSS.log`
- **Content**: All checks with timestamps and detailed messages

## Customization

The script can be customized by modifying the following variables:
- `APPS`: List of Rails applications to check
- `DOMAINS`: List of domains to verify
- `BRGEN_IP`, `HYP_IP`: Server IP addresses
- `BASE_DIR`: Base directory for Rails applications
- Version requirements for Ruby, Node.js, and Rails

## Requirements

### OpenBSD System Requirements
- OpenBSD 7.8 or compatible
- Standard OpenBSD utilities (pfctl, rcctl, etc.)
- Network connectivity for DNS and SSL checks

### Additional Tools
- `nslookup`: For DNS resolution testing
- `openssl`: For SSL certificate verification
- `curl`: For HTTP response testing
- `bc`: For mathematical calculations (optional)

## Troubleshooting

### Common Issues

1. **Command not found errors**
   - Ensure running on OpenBSD system
   - Install missing packages with `pkg_add`

2. **Permission errors**
   - Run with appropriate privileges
   - Check file permissions on configuration files

3. **Network timeouts**
   - Verify network connectivity
   - Check DNS configuration

4. **Service not running**
   - Check service status with `rcctl status`
   - Start services with `rcctl start <service>`

### Getting Help

For issues with specific checks, refer to the suggestion messages provided in the output. Each failed check includes actionable suggestions for resolution.

## Integration

The script can be integrated into:
- **Cron jobs**: Regular automated health checks
- **Monitoring systems**: JSON output for parsing
- **CI/CD pipelines**: Deployment validation
- **Maintenance scripts**: System health verification

## License

This script is part of the pubhealthcare repository and follows the same licensing terms.