# OpenBSD & Rails

This guide details setting up a secure and efficient Ruby on Rails environment on an OpenBSD server using OpenBSD's built-in tools.

## Overview

This setup script performs the following tasks:
- Installs essential packages for Ruby on Rails.
- Configures PostgreSQL for robust database management.
- Sets up Redis for fast caching and background jobs.
- Configures `nsd` for secure DNS services with DNSSEC.
- Sets up `httpd` for handling Let's Encrypt ACME challenges and HTTP requests.
- Configures `relayd` for reverse proxying and TLS termination.
- Sets up `pf` for advanced firewall and network security.
- Generates configuration files for managing domain certificates with Let's Encrypt.
- Optimizes system settings for performance.

## Components

### PostgreSQL
- **Installation and Configuration**: A reliable and scalable database solution.
- **Security**: Runs as an unprivileged user.
- **Performance**: Optimized for high-concurrency workloads.

### Redis
- **Installation and Setup**: Manages caching and background jobs.
- **Speed**: Provides in-memory data storage for fast data access.

### nsd (DNS Server)
- **Configuration**: Primary DNS server with DNSSEC.
- **Security**: Protects against DNS spoofing.
- **Reliability**: Ensures high availability of DNS services.

### httpd (Web Server)
- **ACME Challenge Handling**: Manages ACME challenges from Let's Encrypt.
- **Request Management**: Handles HTTP requests and serves static content.

### relayd (Load Balancer and Proxy)
- **Reverse Proxy**: Forwards client requests to Rails.
- **TLS Termination**: Manages HTTPS connections securely.
- **Performance**: Offloads TLS handling from Rails.

### pf (Packet Filter)
- **Firewall Configuration**: Filters network traffic for security.
- **Network Security**: Implements advanced firewall rules.
- **Performance**: Optimized for minimal latency and maximum throughput.

### acme-client (Let's Encrypt)
- **Certificate Management**: Automatically obtains and renews TLS certificates.
- **Security**: Ensures secure HTTPS connections for all domains.
