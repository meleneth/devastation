# Migrating GitLab Into devastation

`devastation` does not automatically migrate existing GitLab data. It detects local GitLab directories and stops unless migration or explicit reuse is enabled.

## Supported Inputs

Set these variables only when you intend to migrate:

```yaml
gitlab_migration_enabled: true
gitlab_backup_tar: /path/to/backup.tar
gitlab_old_config_path: /path/to/old/gitlab/config
gitlab_old_logs_path: /path/to/old/gitlab/logs
gitlab_old_data_path: /path/to/old/gitlab/data
```

The playbook validates that all migration variables are present. It does not copy old paths automatically yet; use the restore script after the local GitLab service exists.

## Recommended Flow

On the old GitLab container:

```bash
docker exec -t OLD_GITLAB_CONTAINER gitlab-backup create
docker cp OLD_GITLAB_CONTAINER:/var/opt/gitlab/backups/BACKUP_gitlab_backup.tar .
```

Bring up `devastation`:

```bash
./bin/devastation-up -e gitlab_migration_enabled=true \
  -e gitlab_backup_tar=/absolute/path/BACKUP_gitlab_backup.tar \
  -e gitlab_old_config_path=/absolute/path/config \
  -e gitlab_old_logs_path=/absolute/path/logs \
  -e gitlab_old_data_path=/absolute/path/data
```

Restore the backup:

```bash
./bin/devastation-gitlab-restore /absolute/path/BACKUP_gitlab_backup.tar
```

Then verify:

```bash
docker compose -f /srv/devastation/compose/compose.yml exec gitlab gitlab-rake gitlab:check SANITIZE=true
./bin/devastation-validate
```

## Notes

GitLab backup compatibility depends on GitLab version. Prefer restoring into the same GitLab version as the source, then upgrading after the restore succeeds. The image version is controlled by `gitlab_version` in `group_vars/all.yml`.

The standalone `registry.deva.station` remains the canonical local Kubernetes registry. GitLab's integrated registry is disabled in the generated omnibus configuration.
