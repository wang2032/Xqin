#!/bin/sh
set -e

APP_DIR=/var/www/html
STATE_DIR=/var/www/state
mkdir -p "$STATE_DIR"

# 当提供了 DB_HOST 时，按环境变量渲染数据库配置（容器部署路径）。
# 文件内用 getenv() 读取，避免密码含特殊字符时的转义问题。
if [ -n "$DB_HOST" ]; then
    cat > "$APP_DIR/config/database.php" <<'PHP'
<?php
return [
    'host'     => getenv('DB_HOST') ?: 'localhost',
    'port'     => (int)(getenv('DB_PORT') ?: 3306),
    'dbname'   => getenv('DB_NAME') ?: '',
    'username' => getenv('DB_USER') ?: 'root',
    'password' => getenv('DB_PASSWORD') ?: '',
    'charset'  => getenv('DB_CHARSET') ?: 'utf8mb4',
];
PHP
fi

# 把 .installed 安装标记软链到 state 卷，使其在镜像更新/容器重建后仍然保留，
# 否则 index.php 会因检测不到该文件而强制跳回安装向导。
if [ ! -L "$APP_DIR/.installed" ] && [ ! -e "$APP_DIR/.installed" ]; then
    ln -s "$STATE_DIR/.installed" "$APP_DIR/.installed"
fi

chown -R www-data:www-data "$APP_DIR/uploads" "$STATE_DIR" 2>/dev/null || true

exec "$@"
