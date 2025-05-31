import { defineStore } from 'pinia';
import api from '@/config/api';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: localStorage.getItem('jwt') || null,
    passkeyRegistrationOptions: null,
    passkeyAuthenticationOptions: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
  },

  actions: {
    async login(credentials) {
      try {
        const response = await api.post('/sessions', credentials);
        this.token = response.data.jwt;
        localStorage.setItem('jwt', this.token);
        this.user = response.data.user;
        return response;
      } catch (error) {
        console.error('Login failed:', error);
        this.logout(); // Очистить токен при ошибке входа (например, неверные учетные данные)
        throw error; // Перебросить ошибку для обработки в компоненте
      }
    },

    async register(userData) {
      try {
        const response = await api.post('/users', userData);
        // После регистрации можно сразу войти или перенаправить на страницу входа
        this.token = response.data.token; // Если API возвращает токен при регистрации
        localStorage.setItem('jwt', this.token);
        this.user = response.data.user;
        return response;
      } catch (error) {
        console.error('Registration failed:', error);
        throw error; // Перебросить ошибку для обработки в компоненте
      }
    },

    logout() {
      this.user = null;
      this.token = null;
      localStorage.removeItem('jwt');
    },

    // TODO: Добавить действие для загрузки данных пользователя по токену при инициализации приложения
    async fetchUser() {
      if (this.token) {
        try {
          const response = await api.get('/me'); // Использование нового эндпоинта
          this.user = response.data.user; // Сохраняем полученные данные пользователя
           // Заглушка - удалить
          // this.user = { email: 'user@example.com' }; // Имитация загрузки пользователя
        } catch (error) {
          console.error('Failed to fetch user:', error);
          this.logout(); // Выйти, если токен недействителен или ошибка при получении данных пользователя
        }
      }
    },

    // Новые действия для Passkeys

    // Запрос опций регистрации Passkey
    async getPasskeyRegistrationOptions() {
      try {
        const response = await api.get('/passkeys/registration_options');
        this.passkeyRegistrationOptions = response.data;
        return response.data;
      } catch (error) {
        console.error('Failed to get passkey registration options:', error);
        throw error;
      }
    },

    // Отправка ответа регистрации Passkey
    async sendPasskeyRegistrationResponse(response) {
      try {
        const res = await api.post('/passkeys/registration_verification', { passkey_creation_response: response });
        // После успешной регистрации Passkey можно обновить данные пользователя или просто подтвердить успех
        console.log('Passkey registered successfully:', res.data);
        // Возможно, здесь нужно вызвать fetchUser() или добавить информацию о Passkey к user state
        return res.data;
      } catch (error) {
        console.error('Failed to verify passkey registration:', error);
        throw error;
      }
    },

    // Запрос опций аутентификации Passkey
    async getPasskeyAuthenticationOptions() {
      try {
        const response = await api.get('/passkeys/authentication_options');
        this.passkeyAuthenticationOptions = response.data;
        return response.data;
      } catch (error) {
        console.error('Failed to get passkey authentication options:', error);
        throw error;
      }
    },

    // Отправка ответа аутентификации Passkey
    async sendPasskeyAuthenticationResponse(response) {
      try {
        const res = await api.post('/passkeys/authentication_verification', { passkey_authentication_response: response });
        // После успешной аутентификации Passkey получаем новый токен и данные пользователя\n        this.token = res.data.token;\n        localStorage.setItem('jwt', this.token);\n        this.user = res.data.user;\n        console.log('Passkey authenticated successfully:', res.data);\n        return res.data;\n      } catch (error) {\n        console.error('Failed to verify passkey authentication:', error);\n        this.logout(); // Выйти при ошибке аутентификации\n        throw error;\n      }\n    },\n  },\n});
      } catch (error) {
        console.error('Failed to verify passkey authentication:', error);
        this.logout(); // Выйти при ошибке аутентификации
        throw error;
      }
    },
  },
});
