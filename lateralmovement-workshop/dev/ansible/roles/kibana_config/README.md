# Kibana Configuration Role

This Ansible role automatically configures Kibana for Windows event log analysis in an ELK stack environment.

## Features

- Creates index patterns for Winlogbeat data
- Sets up pre-configured saved searches for different log types
- Creates dashboards for security analysis
- Ensures proper integration with Elasticsearch

## Requirements

- Ansible 2.9+
- Kibana 7.17+
- Elasticsearch cluster with proper authentication
- Winlogbeat data ingestion configured

## Role Variables

### Required Variables
- `elastic_user_password`: Password for the elastic superuser

### Optional Variables (with defaults)
- `kibana_url`: Kibana base URL (default: `https://{{ ansible_host }}:5601`)
- `kibana_ready_retries`: Number of retries for Kibana health check (default: 30)
- `kibana_ready_delay`: Delay between retries in seconds (default: 10)

## Dependencies

- `soc_elk`: ELK stack must be installed and configured first

## Example Playbook

```yaml
- hosts: linux_servers
  roles:
    - role: kibana_config
      vars:
        elastic_user_password: "your_secure_password"
```

## Tags

- `kibana_config`: All tasks
- `kibana_health_check`: Health check tasks only
- `index_patterns`: Index pattern creation tasks
- `saved_searches`: Saved search creation tasks
- `dashboards`: Dashboard creation tasks
- `info`: Information display tasks

## Usage

Run specific parts of the role using tags:

```bash
# Only create index patterns
ansible-playbook playbook.yml --tags "index_patterns"

# Skip health checks
ansible-playbook playbook.yml --skip-tags "kibana_health_check"
```

## Created Objects

### Index Patterns
- `winlogbeat-*`: Default pattern for all Winlogbeat data

### Saved Searches
- **Windows Events**: All Windows events from Winlogbeat
- **Sysmon Events**: Filtered for Sysmon operational logs
- **Security Events**: Filtered for Windows Security logs

### Dashboards
- **Windows Security Events**: Overview dashboard for log analysis

## Security Considerations

- Uses elastic superuser credentials (consider creating dedicated Kibana user)
- SSL certificate validation disabled for lab environments
- Passwords should be stored in Ansible Vault for production use

## Troubleshooting

1. **Kibana not ready**: Increase `kibana_ready_retries` and `kibana_ready_delay`
2. **Authentication failures**: Verify `elastic_user_password` is correct
3. **SSL issues**: Check certificate configuration in ELK stack
4. **Missing data**: Ensure Winlogbeat is sending data to Elasticsearch

## License

MIT
