# § OpenBSD Configuration Script Documentation
# Cognitive Framework v10.7.0 Implementation

## Overview

This OpenBSD.sh script provides comprehensive system configuration for OpenBSD 7.8+ with a focus on:
- **Cognitive load management** using 7±2 chunking principles
- **Zero-trust security** with defense-in-depth
- **Performance optimization** for high-traffic applications
- **POSIX compliance** for maximum compatibility
- **Enhanced error handling** with circuit breaker patterns

## Features

### § Security Implementation
- **Zero-trust architecture** with comprehensive input validation
- **Defense-in-depth** security layering
- **DNSSEC configuration** for DNS security
- **SSL/TLS certificate management** with Let's Encrypt
- **Comprehensive security headers** (HSTS, CSP, XSS protection)
- **SSH hardening** with key-based authentication
- **Kernel security parameters** optimization

### § Cognitive Framework Compliance
- **7±2 chunking** for domain and configuration organization
- **Double-quote formatting** throughout script
- **Cognitive headers** with § symbols for section identification
- **Progressive disclosure** of complexity
- **Error recovery** with user-friendly messages
- **Circuit breaker patterns** for automatic failure management

### § Performance Optimization
- **Kernel parameter tuning** for high-performance networking
- **Database connection pooling** configuration
- **File system optimization** with noatime mounts
- **Memory management** tuning for Ruby applications
- **Network buffer optimization** for high throughput
- **Process limit optimization** for concurrent connections

### § System Monitoring
- **Automated health checks** every 5 minutes
- **Resource usage monitoring** with configurable thresholds
- **Service status monitoring** for critical services
- **Structured logging** with JSON format
- **Alert system** for critical issues

## Usage

### Basic Commands

```bash
# Show help and options
doas sh openbsd.sh --help

# Full system setup (infrastructure + applications)
doas sh openbsd.sh

# Infrastructure setup only
doas sh openbsd.sh --infra

# Application deployment only
doas sh openbsd.sh --deploy

# Preview commands without execution
doas sh openbsd.sh --dry-run

# Enable verbose logging
doas sh openbsd.sh --verbose

# Cleanup NSD configuration
doas sh openbsd.sh --cleanup
```

### Configuration Options

The script supports configuration through environment variables:

```bash
# Set custom IP addresses
export BRGEN_IP="your.server.ip"
export HYP_IP="your.secondary.ip"

# Enable debug mode
export DEBUG=true

# Custom application list
export APPS="app1 app2 app3"
```

## Architecture

### § Domain Organization (Cognitive Chunks)

The script organizes 56 domains into cognitive chunks for reduced mental load:

1. **Nordic Region** (11 domains)
2. **British Isles** (7 domains)
3. **Continental Europe** (10 domains)
4. **North America** (11 domains)
5. **Specialized Applications** (17 domains)

Each chunk maintains 7±2 items for optimal cognitive processing.

### § Application Structure

Seven main applications are deployed:
- **brgen**: Main marketplace application
- **amber**: Notification system
- **pubattorney**: Legal assistance platform
- **bsdports**: BSD documentation system
- **hjerterom**: Norwegian healthcare platform
- **privcam**: Privacy-focused camera system
- **blognet**: Blog network platform

### § Security Architecture

```
┌─────────────────────────────────────────────┐
│                Firewall (pf)                │
├─────────────────────────────────────────────┤
│              Load Balancer (relayd)         │
├─────────────────────────────────────────────┤
│                 Web Server (httpd)          │
├─────────────────────────────────────────────┤
│              Application Layer              │
├─────────────────────────────────────────────┤
│               Database (PostgreSQL)         │
│               Cache (Redis)                 │
└─────────────────────────────────────────────┘
```

## Installation Process

### § Prerequisites

1. **OpenBSD 7.8+** freshly installed
2. **Root access** via doas configuration
3. **Network connectivity** for package installation
4. **DNS resolution** properly configured

### § Step-by-Step Installation

1. **Download the script**:
   ```bash
   ftp https://raw.githubusercontent.com/anon987654321/pubhealthcare/main/openbsd/openbsd.sh
   chmod +x openbsd.sh
   ```

2. **Run initial validation**:
   ```bash
   sh openbsd.sh --help
   ```

3. **Execute full setup**:
   ```bash
   doas sh openbsd.sh
   ```

4. **Monitor progress**:
   ```bash
   tail -f ./openbsd_setup.log
   ```

### § Verification Procedures

The script includes comprehensive verification:

```bash
# Run test suite
sh test_openbsd.sh

# Check service status
doas rcctl check httpd relayd postgresql redis nsd

# Verify DNS resolution
dig @localhost example.com

# Test SSL certificates
openssl s_client -connect your.domain.com:443 -servername your.domain.com

# Check firewall rules
doas pfctl -s rules

# Monitor system performance
htop
```

## Configuration Files

### § Generated Files

- `/etc/pf.conf` - Firewall configuration
- `/etc/httpd.conf` - Web server configuration
- `/etc/relayd.conf` - Load balancer configuration
- `/etc/nsd.conf` - DNS server configuration
- `/etc/acme-client.conf` - SSL certificate configuration
- `/var/nsd/zones/master/*.zone` - DNS zone files

### § Log Files

- `./openbsd_setup.log` - Main setup log
- `/var/log/system_monitor.log` - System monitoring log
- `/var/log/httpd/access.log` - Web server access log
- `/var/log/httpd/error.log` - Web server error log

## Troubleshooting

### § Common Issues

1. **Permission denied errors**:
   ```bash
   # Ensure running with doas
   doas sh openbsd.sh
   ```

2. **Package installation failures**:
   ```bash
   # Update package database
   doas pkg_add -u
   # Retry installation
   doas sh openbsd.sh --infra
   ```

3. **Certificate generation failures**:
   ```bash
   # Check ACME challenge directory
   ls -la /var/www/acme/
   # Verify DNS resolution
   dig your.domain.com
   ```

4. **Service startup failures**:
   ```bash
   # Check service logs
   doas rcctl start servicename
   # Review configuration
   doas rcctl check servicename
   ```

### § Performance Tuning

1. **Increase file descriptor limits**:
   ```bash
   # Edit /etc/login.conf
   default:\
       :openfiles-cur=4096:\
       :openfiles-max=8192:
   ```

2. **Optimize database settings**:
   ```bash
   # Edit /var/postgresql/data/postgresql.conf
   shared_buffers = 256MB
   effective_cache_size = 1GB
   ```

3. **Tune kernel parameters**:
   ```bash
   # Edit /etc/sysctl.conf
   net.inet.tcp.sendspace=131072
   net.inet.tcp.recvspace=131072
   ```

## Security Considerations

### § Zero-Trust Implementation

- **All inputs validated** before processing
- **Principle of least privilege** applied
- **Network segmentation** through firewall rules
- **Encrypted communications** enforced
- **Regular security updates** automated

### § Monitoring and Alerting

- **Real-time monitoring** of critical services
- **Automated alerts** for threshold breaches
- **Log aggregation** and analysis
- **Intrusion detection** through log monitoring
- **Performance metrics** tracking

## Maintenance

### § Regular Tasks

1. **Update packages**:
   ```bash
   doas pkg_add -u
   ```

2. **Renew certificates**:
   ```bash
   doas acme-client -v your.domain.com
   ```

3. **Rotate logs**:
   ```bash
   doas newsyslog
   ```

4. **Monitor system health**:
   ```bash
   tail -f /var/log/system_monitor.log
   ```

### § Backup Procedures

1. **Configuration backup**:
   ```bash
   tar -czf config_backup.tar.gz /etc/pf.conf /etc/httpd.conf /etc/relayd.conf
   ```

2. **Database backup**:
   ```bash
   doas -u _postgresql pg_dumpall > database_backup.sql
   ```

3. **SSL certificate backup**:
   ```bash
   tar -czf ssl_backup.tar.gz /etc/ssl/private/ /etc/ssl/*.crt
   ```

## Support

For issues and questions:
- **Repository**: https://github.com/anon987654321/pubhealthcare
- **Test Suite**: Run `sh test_openbsd.sh` for comprehensive validation
- **Documentation**: This README.md file
- **Log Analysis**: Check `./openbsd_setup.log` for detailed execution logs

## License

This script is provided under the same license as the pubhealthcare repository.

---

*§ Cognitive Framework v10.7.0 - Optimized for human cognition and system reliability*
   - `--help`: Show usage.

3. **Stages**:
   - **Stage 1**: Installs `ruby-3.3.5`, `ldns-utils`, `postgresql-server`, `redis`, and `zap` using OpenBSD 7.7’s default `pkg_add`. Configures `ns.brgen.no` (46.23.95.45) as master nameserver with DNSSEC (ECDSAP256SHA256 keys, signed zones), allowing zone transfers to `ns.hyp.net` (194.63.248.53, managed by Domeneshop.no) via TCP 53 and sending NOTIFY via UDP 53, with `pf` permitting TCP/UDP 53 traffic on `ext_if` (vio0). Generates TLSA records for HTTPS services. Issues certificates via Let’s Encrypt. Pauses to let you upload Rails apps (`brgen`, `amber`, `bsdports`) to `/home/<app>/<app>` with `Gemfile` and `database.yml`. Press Enter to proceed, then submit DS records from `/var/nsd/zones/master/*.ds` to Domeneshop.no. Test with `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`, `dig DS brgen.no +short`, and `dig TLSA _443._tcp.brgen.no`. Wait for propagation (24–48 hours) before `--resume`. `ns.hyp.net` requires no local setup (configure slave separately).
   - **Stage 2**: Sets up PostgreSQL, Redis, PF firewall, relayd with security headers, and Rails apps with Falcon server. Logs go to `/var/log/messages`. Applies CSS micro-text (e.g., 7.5pt) for app footer branding if applicable.
   - **Stage 3**: Configures OpenSMTPD for `bergen@pub.attorney`, accessible via `mutt` for `gfuser`.

4. **Verification**:
   - Services: `rcctl check nsd httpd postgresql redis relayd smtpd`.
   - DNS: `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`.
   - DNSSEC: `dig DS brgen.no +short`, `dig DNSKEY brgen.no +short`.
   - TLSA: `dig TLSA _443._tcp.brgen.no`.
   - Firewall: `doas pfctl -s rules` to confirm DNS and other rules.
   - Email: Check `/var/vmail/pub.attorney/bergen/new` as `gfuser` with `mutt`.
   - Logs: `tail -f /var/log/messages` for Rails app activity.
