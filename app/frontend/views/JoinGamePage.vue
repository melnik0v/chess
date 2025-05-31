<template>
  <div>
    <h1>Присоединение к игре...</h1>
    <p v-if="message">{{ message }}</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '@/config/api';

const route = useRoute();
const router = useRouter();
const message = ref('Пожалуйста, подождите...');

onMounted(async () => {
  const invitationToken = route.params.invitationToken; // Получаем токен из параметров маршрута

  if (!invitationToken) {
    message.value = 'Отсутствует токен приглашения.';
    console.error('Invitation token not found in route params.');
    // Возможно, перенаправить на главную или страницу с ошибкой
    return;
  }

  try {
    message.value = 'Попытка присоединиться к игре...';
    const response = await api.post('/games/join', {
      invitation_token: invitationToken,
    });

    const gameId = response.data.id; // Получаем ID игры из ответа

    if (gameId) {
      message.value = 'Успешно присоединились к игре!';
      console.log('Successfully joined game, redirecting to', `/games/${gameId}`);
      router.push({ name: 'GamePage', params: { id: gameId } }); // Перенаправляем на страницу игры
    } else {
      message.value = 'Не удалось получить ID игры из ответа.';
      console.error('Game ID not found in join response:', response.data);
      // Обработать случай, если бэк не вернул ID
    }

  } catch (error) {
    console.error('Ошибка при присоединении к игре:', error);
    if (error.response && error.response.status === 422) {
       // Например, если токен недействителен или игра уже началась
       message.value = `Ошибка: ${error.response.data.message || 'Не удалось присоединиться к игре.'}`;
    } else {
      message.value = 'Произошла ошибка при попытке присоединиться.';
    }
    // TODO: Возможно, перенаправить на главную или страницу с ошибкой после задержки
  }
});
</script>

<style scoped>
/* Стили для этой страницы */
</style>
