#!/bin/bash
# restore-nextcloud-correto.sh

# ============================================
# CONFIGURAÇÕES
# ============================================
VOLUME_ROOT="./volume-nextcloud"
BACKUP_DIR="./nextcloud-backup"
BACKUP_DATE="20260802_162952"  # ← Data do backup a restaurar
CONTAINER_NEXTCLOUD="nextcloud"
CONTAINER_DB="nextcloud_db"
ROOT_PASSWORD=""

# ============================================
# RESTAURAÇÃO
# ============================================
echo "🔄 Iniciando restauração do backup $BACKUP_DATE"

# 1. Parar os containers
echo "⏹️ Parando containers..."
docker compose down

# 2. NÃO remova a pasta nextcloud_html completamente!
# Apenas limpe dados específicos que vamos restaurar
echo "🧹 Limpando dados antigos..."
sudo rm -rf $VOLUME_ROOT/nextcloud_html/data/*
sudo rm -rf $VOLUME_ROOT/nextcloud_html/custom_apps/*
sudo rm -rf $VOLUME_ROOT/nextcloud_html/themes/*
sudo rm -rf $VOLUME_ROOT/nextcloud_html/config/config.php

# 3. Restaurar os dados
echo "📦 Restaurando arquivos..."

# Restaurar config.php
tar -xzf $BACKUP_DIR/nextcloud_config_$BACKUP_DATE.tar.gz -C $VOLUME_ROOT/

# Restaurar dados dos usuários
tar -xzf $BACKUP_DIR/nextcloud_data_$BACKUP_DATE.tar.gz -C $VOLUME_ROOT/

# Restaurar custom_apps
if [ -f "$BACKUP_DIR/nextcloud_custom_apps_$BACKUP_DATE.tar.gz" ]; then
    tar -xzf $BACKUP_DIR/nextcloud_custom_apps_$BACKUP_DATE.tar.gz -C $VOLUME_ROOT/
fi

# Restaurar themes
if [ -f "$BACKUP_DIR/nextcloud_themes_$BACKUP_DATE.tar.gz" ]; then
    tar -xzf $BACKUP_DIR/nextcloud_themes_$BACKUP_DATE.tar.gz -C $VOLUME_ROOT/
fi

# 4. Limpar banco de dados e restaurar
echo "💾 Restaurando banco de dados..."
docker compose up -d db
sleep 10

docker exec -i $CONTAINER_DB mysql -u nextcloud -p${ROOT_PASSWORD} -e "DROP DATABASE IF EXISTS nextcloud; CREATE DATABASE nextcloud;"
docker exec -i $CONTAINER_DB mysql -u nextcloud -p${ROOT_PASSWORD} nextcloud < $BACKUP_DIR/nextcloud_db_$BACKUP_DATE.sql

# 5. Ajustar permissões
echo "🔧 Ajustando permissões..."
sudo chown -R 33:33 $VOLUME_ROOT/nextcloud_html/
sudo chown -R 999:999 $VOLUME_ROOT/nextcloud_db_data/

# 6. Iniciar tudo
echo "🚀 Iniciando stack completa..."
docker compose up -d

# 7. Verificar
sleep 10
docker exec $CONTAINER_NEXTCLOUD php occ status

echo "✅ Restauração concluída! Acesse http://localhost:8080"