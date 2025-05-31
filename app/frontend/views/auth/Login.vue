<template>
  <div class="login-container">
    <h2>Вход</h2>
    <form @submit.prevent="login">
      <div class="p-field">
        <label for="email">Email</label>
        <InputText id="email" type="email" v-model="email" required />
      </div>
      <div class="p-field">
        <label for="password">Пароль</label>
        <InputText id="password" type="password" v-model="password" required />
      </div>
      <Button type="submit" label="Войти" />
    </form>

    <Button v-if="passkeyAvailable" label="Войти с Passkey" icon="pi pi-lock" class="p-button-secondary mt-3" @click="loginWithPasskey" />

    <div v-if="message" :class="{ 'success': isSuccess, 'error': !isSuccess }">{{ message }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router'; // Импорт useRouter
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
// import api from '@/config/api'; // Импорт API клиента - больше не нужен
import { useAuthStore } from '@/stores/auth'; // Импорт authStore

// Функция для конвертации строки base64url в ArrayBuffer
const base64urlToArrayBuffer = (base64url) => {
  // Заменяем символы '-' на '+', '_' на '/' и добавляем паддинг '=' если необходимо
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const pad = base64.length % 4;
  const paddedBase64 = pad ? base64 + '='.repeat(4 - pad) : base64;
  // Декодируем base64 в бинарную строку
  const binaryString = atob(paddedBase64);
  // Конвертируем бинарную строку в ArrayBuffer
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
};

const passkeyAvailable = ref(false)
const email = ref('');
const password = ref('');
const message = ref('');
const isSuccess = ref(false);

const router = useRouter(); // Получение экземпляра роутера
const authStore = useAuthStore(); // Получение экземпляра authStore

const login = async () => {
  message.value = ''; // Очистить предыдущие сообщения
  try {
    // Используем действие login из стора
    await authStore.login({ email: email.value, password: password.value });

    // Axios обрабатывает успешные ответы в блоке try
    message.value = 'Вход успешен!';
    isSuccess.value = true;
    // Сохранить JWT, например, в localStorage - это делает стор
    // localStorage.setItem('jwt', response.data.jwt);
    // console.log('JWT:', response.data.jwt);
    // Перенаправление на главную страницу или страницу профиля
    router.push('/'); // Пример перенаправления на главную

  } catch (error) {
    console.error('Ошибка при входе:', error);
    // Axios помещает информацию об ошибке в error.response
    if (error.response && error.response.data) {
      const data = error.response.data;
      message.value = data.error || 'Ошибка при входе';
    } else {
      message.value = 'Ошибка сети. Пожалуйста, попробуйте позже.';
    }
    isSuccess.value = false;
  }
};

const loginWithPasskey = async () => {
  message.value = '';
  try {
    // 1. Запрос опций аутентификации с бэкенда
    const options = await authStore.getPasskeyAuthenticationOptions();

    // Конвертируем challenge из base64url в ArrayBuffer (необходимо для navigator.credentials)
    // Используем base64urlToArrayBuffer вместо atob
    options.challenge = base64urlToArrayBuffer(options.challenge);

    // Конвертируем allowCredentials.id из base64url в ArrayBuffer
    options.allowCredentials.forEach(cred => {
      // Используем base64urlToArrayBuffer вместо atob
      cred.id = base64urlToArrayBuffer(cred.id);
    });

    // 2. Запрос аутентификации Passkey у браузера/ОС
    const credential = await navigator.credentials.get({
      publicKey: options
    });

    // 3. Отправка ответа на бэкенд для верификации
    // Конвертируем ArrayBuffer в base64url перед отправкой
    const authenticationResponse = {
      id: credential.id,
      rawId: btoa(String.fromCharCode(...new Uint8Array(credential.rawId))), // Конвертация rawId в base64
      response: {
        authenticatorData: btoa(String.fromCharCode(...new Uint8Array(credential.response.authenticatorData))),
        clientDataJSON: btoa(String.fromCharCode(...new Uint8Array(credential.response.clientDataJSON))),
        signature: btoa(String.fromCharCode(...new Uint8Array(credential.response.signature))),
        userHandle: credential.response.userHandle ? btoa(String.fromCharCode(...new Uint8Array(credential.response.userHandle))) : null,
      },
      type: credential.type,
    };

    await authStore.sendPasskeyAuthenticationResponse(authenticationResponse);

    message.value = 'Вход через Passkey успешен!';
    isSuccess.value = true;
    router.push('/');

  } catch (error) {
    console.error('Ошибка при входе с Passkey:', error);
    if (error.response && error.response.data) {
      const data = error.response.data;
      message.value = data.error || 'Ошибка при входе с Passkey';
    } else if (error.name === 'NotAllowedError') {
      message.value = 'Аутентификация Passkey отменена пользователем.';
    } else {
      message.value = 'Ошибка при входе с Passkey. Пожалуйста, попробуйте позже.';
    }
    isSuccess.value = false;
  }
};

// Проверка наличия Passkeys при монтировании компонента
onMounted(async () => {
  // Проверяем поддержку WebAuthn и наличие Passkeys
  if (window.PublicKeyCredential && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable) {
    const isAvailable = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
    if (isAvailable) {
      passkeyAvailable.value = true
      console.log('Passkey is available on this device.');
      // Здесь можно запросить у пользователя, хочет ли он войти с помощью Passkey
      // Или автоматически инициировать процесс, если это предпочтительный метод входа
      // Для начала, просто выведем сообщение или покажем кнопку, если ее нет
    }
  }
});
</script>

<style scoped>
.login-container {
  max-width: 400px;
  margin: 50px auto;
  padding: 20px;
  border: 1px solid #ccc;
  border-radius: 5px;
}
.p-field {
  margin-bottom: 15px;
}
.success {
  color: green;
  margin-top: 10px;
}
.error {
  color: red;
  margin-top: 10px;
}
</style>
