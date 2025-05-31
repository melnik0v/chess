# Настройка WebAuthn
WebAuthn.configure do |config|
  # Укажите "relying party" (RP) ID и название
  # RP ID - это домен вашего сайта (без https://)
  config.rp_id = ENV['WEBAUTHN_RP_ID'] # Используйте переменную окружения
  config.rp_name = "choss"

  # Укажите "origin" вашего сайта (например, "https://localhost:3000")
  # В разработке может быть "http://localhost:3000" или аналогично
  # DEPRECATION WARNING: WebAuthn.origin is deprecated. Use config.allowed_origins instead.
  # config.origin = ENV['WEBAUTHN_ORIGIN'] # Используйте переменную окружения

  # Укажите допустимые "origins" вашего сайта в виде массива
  # Это может быть полезно, если ваше приложение доступно по нескольким адресам (например, localhost и домен)
  config.allowed_origins = [ENV['WEBAUTHN_ORIGIN']].compact # Используйте переменную окружения

  # Дополнительные настройки можно добавить здесь при необходимости
  # Например, для поддержки определенных алгоритмов или аттестации
end
