#!/bin/bash

# تابع اصلی برای مدیریت وردپرس
wp_manage() {
  # بررسی وجود فایل wp-config.php
  if [[ ! -f wp-config.php ]]; then
    echo "Error: wp-config.php not found in current directory"
    exit 1
  fi

  # استخراج اطلاعات پایگاه داده از wp-config.php
  DB_NAME=$(grep "DB_NAME" wp-config.php | grep -o "'[^']*'" | tr -d "'")
  DB_USER=$(grep "DB_USER" wp-config.php | grep -o "'[^']*'" | tr -d "'")
  DB_PASSWORD=$(grep "DB_PASSWORD" wp-config.php | grep -o "'[^'] 0-9a-zA-Z!@#$%^&*()_+=-]*" | tr -d "'")
  TABLE_PREFIX=$(grep "table_prefix" wp-config.php | grep -o "'[^']*'" | tr -d "'")

  # تابع برای اجرای پرس‌وجوهای MySQL
  run_query() {
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "$1" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to execute query"
      return 1
    fi
    return 0
  }

  # تابع برای دریافت مقدار از جدول options
  get_option() {
    local option_name=$1
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e \
      "SELECT option_value FROM ${TABLE_PREFIX}options WHERE option_name='$option_name';"
  }

  # تابع برای تنظیم مقدار در جدول options
  set_option() {
    local option_name=$1
    local option_value=$2
    run_query "INSERT INTO ${TABLE_PREFIX}options (option_name, option_value) \
               VALUES ('$option_name', '$option_value') \
               ON DUPLICATE KEY UPDATE option_value='$option_value';"
  }

  # تابع برای نمایش و مدیریت افزونه‌ها
  manage_plugins() {
    local active_plugins=$(get_option active_plugins)
    echo "Active Plugins: $active_plugins"
    read -p "Enter plugin to disable (or 'exit' to quit): " plugin
    if [[ "$plugin" == "exit" ]]; then
      return
    fi
    # فرض می‌کنیم active_plugins به‌صورت سریال‌سازی‌شده است
    new_plugins=$(echo "$active_plugins" | php -r 'echo serialize(array_diff(unserialize(file_get_contents("php://stdin")), ["'"$plugin"'"]));')
    set_option active_plugins "$new_plugins"
    echo "Plugin $plugin disabled."
  }

  # منوی اصلی
  case $1 in
    "config")
      echo "WordPress Configuration:"
      echo "  Database Name: $DB_NAME"
      echo "  Database User: $DB_USER"
      echo "  Database Password: $DB_PASSWORD"
      echo "  Table Prefix: $TABLE_PREFIX"
      ;;
    "home")
      if [[ "$2" == "set" && -n "$3" ]]; then
        set_option home "$3"
        set_option siteurl "$3"
        echo "Home and Site URL set to: $3"
      else
        echo "Home URL: $(get_option home)"
        echo "Site URL: $(get_option siteurl)"
      fi
      ;;
    "theme")
      if [[ "$2" == "set" && -n "$3" ]]; then
        set_option template "$3"
        set_option stylesheet "$3"
        echo "Theme set to: $3"
      else
        echo "Template: $(get_option template)"
        echo "Stylesheet: $(get_option stylesheet)"
      fi
      ;;
    "plugins")
      manage_plugins
      ;;
    *)
      echo "Usage: $0 {config|home [set URL]|theme [set THEME]|plugins}"
      echo "Example: $0 home set http://example.com"
      exit 1
      ;;
  esac
}

# اجرای تابع اصلی
wp_manage "$@"
