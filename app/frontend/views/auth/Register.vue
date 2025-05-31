<template>
  <div class="register-container">
    <h2>Регистрация</h2>
    <form @submit.prevent="register">
      <div class="p-field">
        <label for="email">Email</label>
        <InputText id="email" type="email" v-model="email" required />
      </div>
      <div class="p-field">
        <label for="password">Пароль</label>
        <InputText id="password" type="password" v-model="password" required />
      </div>
      <div class="p-field">
        <label for="password_confirmation">Подтверждение пароля</label>
        <InputText id="password_confirmation" type="password" v-model="password_confirmation" required />
      </div>
      <Button type="submit" label="Зарегистрироваться" />
    </form>
    <div v-if="message" :class="{ 'success': isSuccess, 'error': !isSuccess }">{{ message }}</div>

    <Button v-if="isSuccess && !passkeyRegistered" label="Зарегистрировать Passkey" class="p-button-secondary mt-3" @click="registerPasskey" />
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';
import { useAuthStore } from '@/stores/auth'; // Импорт authStore
// import api from '@/config/api'; // Импорт API клиента - больше не нужен

const email = ref('');
const password = ref('');
const password_confirmation = ref('');
const message = ref('');
const isSuccess = ref(false);
const passkeyRegistered = ref(false); // Новое состояние для отслеживания регистрации Passkey

const router = useRouter();
const authStore = useAuthStore(); // Получение экземпляра authStore

const register = async () => {
  message.value = '';
  isSuccess.value = false;
  passkeyRegistered.value = false; // Сбрасываем состояние Passkey
  try {
    const response = await authStore.register({
      user: {
        email: email.value,
        password: password.value,
        password_confirmation: password_confirmation.value,
      },
    });

    message.value = response.data.message || 'Регистрация успешна!';
    isSuccess.value = true;
    // Не перенаправляем сразу, ждем возможной регистрации Passkey
    // router.push('/login');

  } catch (error) {
    console.error('Ошибка при регистрации:', error);
    if (error.response && error.response.data) {
      const data = error.response.data;
      message.value = data.errors ? data.errors.join(', ') : data.error || 'Ошибка при регистрации';
    } else {
      message.value = 'Ошибка сети. Пожалуйста, попробуйте позже.';
    }
    isSuccess.value = false;
  }
};

const registerPasskey = async () => {
  message.value = '';
  try {
    // 1. Запрос опций регистрации с бэкенда
    // Предполагаем, что текущий пользователь доступен на бэкенде после регистрации email/password
    const options = await authStore.getPasskeyRegistrationOptions();

    // Конвертируем challenge и user.id из base64url в ArrayBuffer
    options.challenge = Uint8Array.from(atob(options.challenge), c => c.charCodeAt(0));
    options.user.id = Uint8Array.from(atob(options.user.id), c => c.charCodeAt(0));

    // Конвертируем excludeCredentials.id из base64url в ArrayBuffer, если они есть
    if (options.excludeCredentials) {
      options.excludeCredentials.forEach(cred => {
        cred.id = Uint8Array.from(atob(cred.id), c => c.charCodeAt(0));
      });
    }

    // 2. Запрос создания Passkey у браузера/ОС
    const credential = await navigator.credentials.create({
      publicKey: options
    });

    // 3. Отправка ответа на бэкенд для верификации и сохранения
    // Конвертируем ArrayBuffer в base64url перед отправкой\n    const creationResponse = {\n      id: credential.id,\n      rawId: btoa(String.fromCharCode(...new Uint8Array(credential.rawId))), // Конвертация rawId в base64\n      response: {\n        attestationObject: btoa(String.fromCharCode(...new Uint8Array(credential.response.attestationObject))),\n        clientDataJSON: btoa(String.fromCharCode(...new Uint8Array(credential.response.clientDataJSON))),\n      },\n      type: credential.type,\n    };\n\n    await authStore.sendPasskeyRegistrationResponse(creationResponse);

    message.value = 'Passkey успешно зарегистрирован!';
    isSuccess.value = true;
    passkeyRegistered.value = true; // Отмечаем, что Passkey зарегистрирован

    // После регистрации Passkey или отказа, перенаправляем на страницу входа
    // router.push('/sign-in'); // или на главную: router.push('/');

  } catch (error) {
    console.error('Ошибка при регистрации Passkey:', error);
    if (error.name === 'NotAllowedError') {
      message.value = 'Регистрация Passkey отменена пользователем.';
    } else if (error.response && error.response.data) {
      const data = error.response.data;
      message.value = data.error || 'Ошибка при регистрации Passkey';
    } else {
      message.value = 'Ошибка при регистрации Passkey. Пожалуйста, попробуйте позже.';
    }
    isSuccess.value = false;
    passkeyRegistered.value = false;

    // Все равно перенаправляем после попытки регистрации Passkey
    // router.push('/sign-in'); // или на главную: router.push('/');
  }
  // Перенаправляем в любом случае после попытки регистрации Passkey
  router.push('/sign-in');
};

</script>

<style scoped>
.register-container {
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
