<template>
  <div class="game-page-container">
    <!-- Здесь будет отображаться шахматная доска и информация об игре -->

    <template v-if="gameData">
      <!-- Отображение доски -->
      <!-- Передаем цвет текущего игрока в ChessBoard -->
      <ChessBoard :fen="gameData.fen" :current-player-color="currentPlayerColor" @move-made="handleMoveMade" />

      <!-- Кнопка присоединения -->
      <!-- Отображаем кнопку, если игра ожидает игрока И текущий пользователь НЕ является ни белым, ни черным игроком -->
      <Button
        v-if="gameData.state === 'waiting_for_player' && authStore.user && authStore.user.id && gameData.white_player_id !== authStore.user.id && gameData.black_player_id !== authStore.user.id"
        label="Присоединиться к игре"
        @click="joinGame"
      />

      <!-- Ссылка-приглашение (отображается только создателю игры, пока игра ожидает игрока) -->
      <div v-if="isCreator && gameData.state === 'waiting_for_player'">
        <p>Ссылка для приглашения друга:</p>
        <p>{{ invitationLink }}</p>
      </div>

      <div class="actions-container">
        <Button
          v-if="gameData.state === 'in_progress' && isCurrentPlayerInGame"
          label="Сдаться"
          @click="resignGame"
          severity="danger"
        />
        <Button
          v-if="gameData.state === 'waiting_for_player' && isCurrentPlayerInGame"
          label="Копировать ссылку приглашения"
          @click="copyInvitationLink"
          severity="secondary"
        />
      </div>
    </template>

    <div v-else>
      <p>Загрузка данных игры...</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
// import axios from 'axios'; // Удаляем прямой импорт axios
import api from '@/config/api'; // Импортируем настроенный api клиент
import { useAuthStore } from '@/stores/auth';
import Button from 'primevue/button';
import ChessBoard from '@/components/ChessBoard.vue';
import { useGameStore } from '@/stores/game';

const route = useRoute();
const router = useRouter(); // Инициализируем useRouter
const authStore = useAuthStore();
const gameStore = useGameStore();

const gameId = route.params.id;
const gameData = ref(null);
const pollingInterval = ref(null);

// Определяем, является ли текущий пользователь создателем игры
const isCreator = computed(() => {
  // Проверяем наличие и gameData, и authStore.user, и authStore.user.id
  if (!gameData.value || !authStore.user || !authStore.user.id) return false;
  return gameData.value.white_player_id === authStore.user.id || gameData.value.black_player_id === authStore.user.id;
});

// Определяем, является ли текущий пользователь игроком в этой игре
// Это вычисляемое свойство теперь используется только для внутренней логики (например, автоматического присоединения), но не для отображения кнопки
const isCurrentPlayerInGame = computed(() => {
  // Проверяем наличие и gameData, и authStore.user, и authStore.user.id
  if (!gameData.value || !authStore.user || !authStore.user.id) return false;
  console.log('Вычисление isCurrentPlayerInGame (для внутренней логики):', {
    gameData: gameData.value,
    currentUser: authStore.user,
    whitePlayerId: gameData.value.white_player_id,
    blackPlayerId: gameData.value.black_player_id,
    currentUserId: authStore.user.id, // Теперь здесь должно быть правильное ID
    isWhitePlayer: gameData.value.white_player_id === authStore.user.id,
    isBlackPlayer: gameData.value.black_player_id === authStore.user.id,
    result: gameData.value.white_player_id === authStore.user.id || gameData.value.black_player_id === authStore.user.id
  });
  return gameData.value.white_player_id === authStore.user.id || gameData.value.black_player_id === authStore.user.id;
});

// Определяем цвет текущего пользователя
const currentPlayerColor = computed(() => {
  // Проверяем наличие и gameData, и authStore.user, и authStore.user.id
  if (!gameData.value || !authStore.user || !authStore.user.id) return null;
  if (gameData.value.white_player_id === authStore.user.id) return 'w';
  if (gameData.value.black_player_id === authStore.user.id) return 'b';
  return null;
});

// Формируем ссылку-приглашение
const invitationLink = computed(() => {
  if (gameData.value && gameData.value.invitation_token) {
    return `${window.location.origin}/games/join/${gameData.value.invitation_token}`;
  }
  return '';
});

const copyInvitationLink = () => {
  navigator.clipboard.writeText(invitationLink.value);
  console.log('Ссылка-приглашение скопирована в буфер обмена:', invitationLink.value);
};

// Функция для загрузки данных игры
const fetchGameData = async () => {
  try {
    const response = await api.get(`/games/${gameId}`);
    gameData.value = response.data;
    console.log('Данные игры загружены:', gameData.value);
    gameStore.setGameData(response.data);
    gameStore.setCurrentPlayerColor(currentPlayerColor.value);

  } catch (error) {
    console.error('Ошибка при загрузке данных игры:', error);
    // TODO: Обработать ошибку (например, перенаправить на главную)
  }
};

onMounted(() => {
  fetchGameData();

  // Начинаем поллинг для обновления состояния игры каждую 1 секунду (1000 мс)
  pollingInterval.value = setInterval(fetchGameData, 1000);
});

// Добавляем хук жизненного цикла для очистки интервала при размонтировании компонента
onUnmounted(() => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value);
    console.log('Polling interval cleared.');
  }
});

// Если gameData обновляется (например, после хода или присоединения),
// убедимся, что ChessBoard реагирует на изменения FEN
// (Это уже обрабатывается в ChessBoard через watch)

// Watcher для реактивного обновления доски при изменении цвета текущего игрока
watch(currentPlayerColor, (newColor) => {
  console.log('Watcher: currentPlayerColor изменился на', newColor);
  // Здесь не нужно принудительно обновлять gameData, т.к.
  // ChessBoard уже реагирует на изменения currentPlayerColor через свой watcher
  // Оставляем этот watcher в GamePage для отладки и понимания потока данных
});

const joinGame = async () => {
  try {
    const response = await api.post('/games/join', {
      invitation_token: gameData.value.invitation_token,
    });
    gameData.value = response.data;
    console.log('Успешно присоединились к игре:', gameData.value);

  } catch (error) {
    console.error('Ошибка при присоединении к игре:', error);
    // TODO: Обработать ошибку присоединения
  }
};

const handleMoveMade = async (moveData) => {
  console.log('Ход сделан, отправляем на бэкенд:', moveData);
  try {
    const response = await api.put(`/games/${gameId}`, {
      game: {
        fen: moveData.fen,
      }
    });
    if (response.data) {
      gameStore.setGameData(response.data);
      console.log('Данные игры обновлены после хода:', gameData.value);
    } else {
      console.warn('PUT request for move was successful, but no game data returned.', response);
    }

  } catch (error) {
    console.error('Ошибка при отправке хода:', error);
    // TODO: Обработать ошибку, возможно, откатить ход на фронтенде
  }
};

// Watcher для автоматического присоединения при наличии токена в URL
watch(gameData, (newValue) => {
  // Этот watcher больше не нужен, так как логика присоединения перенесена в JoinGamePage
});

// Watcher для остановки поллинга при завершении игры
watch(() => gameData.value?.state, (newState) => {
  if (newState && newState !== 'waiting_for_player' && newState !== 'in_progress') {
    if (pollingInterval.value) {
      clearInterval(pollingInterval.value);
      console.log('Polling stopped: Game finished.', newState);
    }
  }
});

// Watcher для отладки isCurrentPlayerInGame при изменении gameData или authStore.user
// Оставляем этот лог, чтобы видеть, как вычисляется isCurrentPlayerInGame, даже если он не используется для кнопки
watch([gameData, () => authStore.user], ([newGameData, newUser]) => {
  console.log('Watcher: gameData или authStore.user изменились. Пересчитываем isCurrentPlayerInGame.', {
    newGameData: newGameData,
    newUser: newUser,
    isCurrentPlayerInGameValue: isCurrentPlayerInGame.value
  });
});

// Метод для сдачи игры
const resignGame = async () => {
  if (!gameData.value || !isCurrentPlayerInGame.value) return;

  const resignationState = currentPlayerColor.value === 'w' ? 'white_resigns' : 'black_resigns';
  console.log(`Игрок ${currentPlayerColor.value} сдается. Новое состояние: ${resignationState}`);

  try {
    const response = await api.put(`/games/${gameId}`, {
      game: {
        state: resignationState,
      }
    });
    if (response.data) {
      gameData.value = response.data;
      console.log('Игра обновлена после сдачи:', gameData.value);
    } else {
      console.warn('PUT request for resignation was successful, but no game data returned.', response);
    }

  } catch (error) {
    console.error('Ошибка при сдаче игры:', error);
    // TODO: Обработать ошибку сдачи
  }
};

</script>

<style scoped>
/* Стили для контейнера страницы игры */
.game-page-container {
  display: flex;
  flex-direction: column; /* Оставляем column для выравнивания элементов друг под другом, если они появятся */
  padding: 10px;
  box-sizing: border-box;
  align-items: center; /* Центрируем элементы по горизонтали */
  justify-content: flex-start; /* Центрируем элементы по вертикали */
  flex-grow: 1;
  width: 100%;
  height: 100%;
  overflow: hidden;
  position: relative;
}

.actions-container {
  height: 100px;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
