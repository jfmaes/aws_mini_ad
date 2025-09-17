# Winlogbeat Role

This Ansible role installs and configures Winlogbeat on Windows hosts to forward event logs to an ELK stack.

## Features

- Downloads and installs Winlogbeat 7.17.18
- Configures event log collection (Application, Security, System, Sysmon, PowerShell, Terminal Services)
- Sets up Logstash output (non-SSL by default for lab environments)
- Validates configuration and connectivity
- Ensures consistent configuration across all Windows hosts

## Requirements

- Ansible 2.9+
- Windows hosts with PowerShell
- Network connectivity to Logstash server
- Sysmon installed (for Sysmon event collection)

## Role Variables

### Required Variables
- `soc_machine_ip`: IP address of the SOC/ELK server

### Optional Variables (with defaults)
- `winlogbeat_version`: Version to install (default: "7.17.18")
- `winlogbeat_dir`: Installation directory (default: "C:\\Program Files\\Winlogbeat")
- `winlogbeat_output_type`: Output type (default: "logstash")
- `winlogbeat_ssl_enabled`: Enable SSL (default: false)

## Dependencies

- `soc_elk`: ELK stack should be configured on the target server

## Example Playbook

```yaml
- hosts: windows
  vars:
    soc_machine_ip: "{{ hostvars['soc']['ansible_host'] }}"
  roles:
    - winlogbeat
```

## Configuration

The role automatically configures Winlogbeat to:
- Collect from multiple Windows event logs
- Add host and cloud metadata
- Forward to Logstash on port 5044 (non-SSL)
- Disable ILM and template setup (handled by Logstash)

## SSL Configuration

By default, SSL is disabled for lab environments. The role includes tasks to remove any SSL configuration remnants to ensure consistency.

## Validation

The role includes validation steps:
- Configuration syntax validation
- Output connectivity testing (with error tolerance)
- Service status verification

## Handlers

- `Restart Winlogbeat`: Restarts the service when configuration changes

## Files Structure

```
roles/winlogbeat/
├── defaults/main.yml          # Default variables
├── tasks/main.yml             # Main tasks
├── templates/winlogbeat.yml.j2 # Configuration template
├── handlers/main.yml          # Service handlers
├── meta/main.yml             # Role metadata
└── README.md                 # This file
```

## Security Considerations

- Service runs as LocalSystem
- No SSL encryption in default lab configuration
- Consider enabling SSL for production environments
- Logs may contain sensitive information

## Troubleshooting

1. **Service won't start**: Check configuration syntax with validation task
2. **No data in ELK**: Verify network connectivity and Logstash configuration
3. **SSL errors**: Ensure SSL settings match between Winlogbeat and Logstash
4. **Permission issues**: Verify service account has proper permissions

## License

MIT
