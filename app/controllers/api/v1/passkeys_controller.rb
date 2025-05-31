class Api::V1::PasskeysController < ApplicationController
  # before_action :authenticate_request, only: [:registration_options, :registration_verification]

  def registration_options
    # Находим текущего пользователя (предполагается, что пользователь аутентифицирован классическим методом)
    # Если регистрация Passkey возможна сразу после регистрации email/password,
    # то пользователь уже должен быть доступен (например, через current_user).
    # Для простоты примера, предположим, что пользователь с ID 1 существует.
    # В реальном приложении здесь будет логика определения текущего пользователя.
    user = current_user

    if user
      options = ::WebAuthn::Credential.options_for_create(
        user: {
          id: user.id.to_s, # User ID должен быть строкой
          name: user.email, # User name обычно email
          display_name: user.email # Display name также может быть email или другим уникальным идентификатором
        },
        exclude: user.passkeys.pluck(:external_id), # Исключаем уже зарегистрированные ключи пользователя
        authenticator_selection: {
          authenticator_attachment: "platform", # Требуем использование платформенного аутентификатора (например, Touch ID, Windows Hello)
          user_verification: "required" # Требуем верификацию пользователя (например, PIN, биометрия)
        }
      )

      # Сохраняем challenge в сессии для последующей верификации
      # В продакшене рассмотрите более надежное хранилище, чем сессия Rails,
      # особенно если фронтенд и бэкенд находятся на разных доменах или если вы используете stateless API.
      session[:current_registration_challenge] = options.challenge

      render json: options, status: :ok
    else
      render json: { error: "Пользователь не найден" }, status: :not_found
    end
  end

  def registration_verification
    user = current_user

    if user
      webauthn_credential = ::WebAuthn::Credential.new(params[:passkey_creation_response])

      begin
        # Верификация ответа от клиента
        # Используем сохраненный challenge из сессии
        # Проверяем на уникальность ключа при регистрации
        ::WebAuthn.verify_registration_response(
          webauthn_credential,
          session[:current_registration_challenge],
          user_verification: "required"
        )

        # Проверяем, что public_key еще не зарегистрирован для этого пользователя
        if user.passkeys.exists?(public_key: webauthn_credential.public_key)
          raise ActiveRecord::RecordInvalid.new(Passkey.new), "Этот Passkey уже зарегистрирован для вашего пользователя."
        end

        # Сохранение нового Passkey
        passkey = user.passkeys.create!(
          external_id: webauthn_credential.cred_id,
          public_key: webauthn_credential.public_key,
          nickname: "Passkey for #{user.email}", # Можно запросить у пользователя никнейм
          sign_count: webauthn_credential.sign_count
        )

        # Очистка challenge после успешной верификации
        session.delete(:current_registration_challenge)

        render json: { message: "Passkey успешно зарегистрирован!", passkey: passkey }, status: :created

      rescue ::WebAuthn::Error => e
        Rails.logger.error "WebAuthn Registration Error: #{e.message}"
        render json: { error: "Не удалось зарегистрировать Passkey. Пожалуйста, попробуйте снова.", details: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Passkey Save Error: #{e.message}"
        render json: { error: "Не удалось сохранить Passkey. Возможно, этот ключ уже зарегистрирован.", details: e.message }, status: :unprocessable_entity
      end

    else
      render json: { error: "Пользователь не найден" }, status: :not_found
    end
  end

  def authentication_options
    # Генерируем опции аутентификации
    options = ::WebAuthn::Credential.options_for_get(
      allow: Passkey.all.pluck(:external_id), # Разрешаем аутентификацию с любым зарегистрированным Passkey
      user_verification: "preferred" # Предпочитаем верификацию пользователя, но не требуем строго
    )

    # Сохраняем challenge в сессии для последующей верификации
    session[:current_authentication_challenge] = options.challenge

    render json: options, status: :ok
  end

  def authentication_verification
    webauthn_credential = ::WebAuthn::Credential.new(params[:passkey_authentication_response])

    begin
      # Верификация ответа от клиента
      # Используем сохраненный challenge из сессии
      # Получаем passkey по external_id из ответа
      passkey = Passkey.find_by(external_id: webauthn_credential.cred_id)

      raise "Passkey не найден" unless passkey

      ::WebAuthn.verify_authentication_response(
        webauthn_credential,
        session[:current_authentication_challenge],
        passkey.public_key,
        passkey.sign_count,
        user_verification: "preferred" # Должно совпадать с тем, что было в authentication_options
      )

      # Обновляем sign_count и last_used_at после успешной аутентификации
      passkey.update!(sign_count: webauthn_credential.sign_count, last_used_at: Time.current)

      # Очистка challenge после успешной верификации
      session.delete(:current_authentication_challenge)

      # Аутентификация успешна, выдаем JWT
      token = JsonWebToken.encode(user_id: passkey.user.id)
      render json: { user: passkey.user.as_json(only: [:id, :email]), token: token }, status: :ok

    rescue ::WebAuthn::Error => e
      Rails.logger.error "WebAuthn Authentication Error: #{e.message}"
      render json: { error: "Не удалось аутентифицировать Passkey. Пожалуйста, попробуйте снова.", details: e.message }, status: :unauthorized
    rescue => e # Ловим другие возможные ошибки (например, Passkey не найден)
      Rails.logger.error "Authentication Error: #{e.message}"
      render json: { error: "Не удалось аутентифицировать. Проверьте учетные данные.", details: e.message }, status: :unauthorized
    end
  end
end
