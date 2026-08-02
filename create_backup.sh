#!/bin/bash
# backup-nextcloud-correto.sh

# ============================================
# CONFIGURAÇÕES - MUDE AQUI!
# ============================================
VOLUME_ROOT="/home/eloy/docker-volumes"  # ← MUDE para o caminho real
BACKUP_DIR="/home/eloy/nextcloud-backup"   # ← Onde salvar os backups
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_NEXTCLOUD="nextcloud"
CONTAINER_DB="nextcloud_db"
ROOT_PASSWORD=""


# ============================================
# INÍCIO DO BACKUP
# ============================================
echo "🚀 Iniciando backup correto do Nextcloud em $DATE"

mkdir -p $BACKUP_DIR

# 1. Ativar modo manutenção
echo "🔒 Ativando modo manutenção..."
docker exec $CONTAINER_NEXTCLOUD php occ maintenance:mode --on

# 2. Backup do banco de dados
echo "💾 Exportando banco de dados..."
docker exec $CONTAINER_DB mysqldump --single-transaction --quick \
  -u nextcloud -p${ROOT_PASSWORD} nextcloud > $BACKUP_DIR/nextcloud_db_$DATE.sql

# 3. Backup SOMENTE dos arquivos importantes
echo "📦 Compactando arquivos essenciais..."
cd $VOLUME_ROOT

# Backup do config.php (seu arquivo personalizado)
tar -czf $BACKUP_DIR/nextcloud_config_$DATE.tar.gz nextcloud_html/config/config.php

# Backup dos dados dos usuários
tar -czf $BACKUP_DIR/nextcloud_data_$DATE.tar.gz \
  --exclude='nextcloud_html/data/nextcloud.log' \
  --exclude='nextcloud_html/data/audit.log' \
  --exclude='nextcloud_html/data/updater-*' \
  --exclude='nextcloud_html/data/cache' \
  --exclude='nextcloud_html/data/session' \
  --exclude='nextcloud_html/data/tmp' \
  nextcloud_html/data/

# Backup de custom_apps (se existir)
if [ -d "nextcloud_html/custom_apps" ]; then
    tar -czf $BACKUP_DIR/nextcloud_custom_apps_$DATE.tar.gz nextcloud_html/custom_apps/
fi

# Backup de themes (se existir)
if [ -d "nextcloud_html/themes" ]; then
    tar -czf $BACKUP_DIR/nextcloud_themes_$DATE.tar.gz nextcloud_html/themes/
fi

# 4. Desativar modo manutenção
echo "🔓 Desativando modo manutenção..."
docker exec $CONTAINER_NEXTCLOUD php occ maintenance:mode --off

echo "✅ Backup concluído com sucesso!"
echo "📁 Local: $BACKUP_DIR"
ls -lh $BACKUP_DIR/ | grep $DATE