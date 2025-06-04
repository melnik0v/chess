<template>
  <div class="game-page-container">
    <!-- Здесь будет отображаться шахматная доска и информация об игре -->

    <template v-if="gameStore.gameData">
      <div v-if="gameStore.joinStatus === 'failed'" class="join-failed-message">
        <p>Не удалось присоединиться к игре: {{ gameStore.joinError }}</p>
        <p>Эта игра уже занята или недоступна.</p>
        <Button label="На главную" @click="router.push('/')" />
      </div>

      <template v-else>
        <ChessBoard @move-made="handleMoveMade" />

        <div class="actions-container">
          <Button
            v-if="gameStore.gameData.state === 'waiting_for_player'"
            label="Копировать ссылку приглашения"
            @click="copyInvitationLink"
            severity="secondary"
          />
          <Button
            v-if="gameStore.gameData.state === 'in_progress' && gameStore.currentPlayerColor"
            label="Сдаться"
            @click="resignGame"
            severity="danger"
          />
          <div class="game-info">
            <p v-if="gameStore.gameData.state === 'waiting_for_player'">Ожидание второго игрока...</p>
            <p v-else-if="gameStore.gameData.state === 'in_progress'">Игра в процессе. Ход: {{ gameStore.gameData.turn === 'w' ? 'Белых' : 'Черных' }}</p>
            <p v-else-if="gameStore.gameData.state === 'white_resigns'">Игра завершена: Белые сдались.</p>
            <p v-else-if="gameStore.gameData.state === 'black_resigns'">Игра завершена: Черные сдались.</p>
            <p v-else-if="gameStore.gameData.state === 'stalemate'">Игра завершена: Пат.</p>
            <p v-else-if="gameStore.gameData.state === 'checkmate'">Игра завершена: Мат. Победили {{ gameStore.gameData.turn === 'w' ? 'Черные' : 'Белые' }}</p>
            <p v-else-if="gameStore.gameData.state === 'draw'">Игра завершена: Ничья.</p>
            <p v-else>Состояние игры: {{ gameStore.gameData.state }}</p>

            <div v-if="gameStore.gameStatus && gameStore.gameStatus !== 'playing'" class="game-status">
              <p v-if="gameStore.gameStatus === 'checkmate'">Мат! {{ gameStore.winner === 'w' ? 'Белые' : 'Черные' }} выиграли.</p>
              <p v-else-if="gameStore.gameStatus === 'stalemate'">Пат! Ничья.</p>
              <p v-else-if="gameStore.gameStatus === 'draw'">Ничья.</p>
              <p v-else-if="gameStore.gameStatus === 'check'">Шах!</p>
            </div>
          </div>
        </div>
      </template>
    </template>

    <div v-else-if="gameStore.joinStatus !== 'failed'">
      <p>Загрузка данных игры...</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useDeviceStore } from '@/stores/device';
import { useGameStore } from '@/stores/game';

import Button from 'primevue/button';
import ChessBoard from '@/components/ChessBoard.vue';

const gameStore = useGameStore();
const route = useRoute();
const router = useRouter();
const deviceStore = useDeviceStore();

const invitationLink = computed(() => window.location.href);
const copyInvitationLink = () => {
  navigator.clipboard.writeText(invitationLink.value);
  console.log('Ссылка-приглашение скопирована в буфер обмена:', invitationLink.value);
};

onMounted(async () => {
  await deviceStore.loadFingerprint();
  try {
    await gameStore.fetchGame(route.params.uuid);
    gameStore.startPolling();
  } catch (e) {
    if (e.message === 'not_found') {
        router.push('/');
    } else {
        console.error('Ошибка при загрузке игры на старте:', e);
        // Возможно, показать сообщение об ошибке пользователю
    }
  }
});

onUnmounted(() => {
  gameStore.stopPolling();
  gameStore.resetGame();
});

watch(() => route.params.uuid, async (newUuid, oldUuid) => {
  gameStore.resetGame();
  gameStore.stopPolling();
  try {
    await gameStore.fetchGame(newUuid);
    gameStore.startPolling();
  } catch (e) {
    if (e.message === 'not_found') {
        router.push('/');
    } else {
        console.error('Ошибка при смене игры:', e);
        // Возможно, показать сообщение об ошибке
    }
  }
});

const handleMoveMade = async (moveData) => {
  await gameStore.updateGame(route.params.uuid, moveData.fen);
};

const resignGame = async () => {
  await gameStore.resignGame(route.params.uuid);
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

.game-info {
    font-size: 1em;
    text-align: center;
    display: flex;
    gap: 50px;
}

.actions-container {
    margin-top: 20px;
    display: flex;
    gap: 10px;
}

.join-failed-message {
    margin-top: 50px;
    font-size: 1.2em;
    color: red;
    text-align: center;
}
.join-failed-message button {
    margin-top: 15px;
}
</style>
