# Changelog

All notable changes to this Bicep module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Customer-managed key (CMK) support
- Certificate management module
- Key management module
- Access policy fallback support

## [1.0.0] - 2026-02-08

### Added

- Initial release of Key Vault module
- RBAC authorization (required, enforced)
- Soft delete enabled with configurable retention (default 90 days)
- Purge protection enabled by default
- Public network access disabled by default
- Private endpoint configuration support
- Firewall settings with virtual network and IP rules
- Trusted Microsoft services bypass configuration
- Diagnostic settings with Log Analytics workspace integration
- Default workspace fallback configuration
- Resource lock (CanNotDelete) implementation
- RBAC role assignment support scoped to Key Vault
- Secret management sub-module
- Comprehensive tagging support
- Custom type definitions for complex parameters

### Testing

- Pester 5.x unit tests with full module validation
- Native Bicep build and what-if testing
- PSRule analysis for Azure best practices
- Test parameters and configuration files

### CI/CD

- Static analysis workflow (static-test.yaml)
- Unit testing workflow using Pester (unit-tests.yaml)
- Automated ACR deployment workflow (deploy-module.yaml)
- GitHub Actions integration with test result publishing

### Security

- RBAC authorization enforced (no access policies)
- Soft delete and purge protection enabled
- Public network access disabled
- Network ACLs default to Deny
- Private endpoint support

### Documentation

- Comprehensive README with usage examples
- Testing documentation and guidelines
- CI/CD workflow documentation
