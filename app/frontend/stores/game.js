import { defineStore } from 'pinia';
import { ref, computed, watch } from 'vue';
import api from '@/config/api';
import { useDeviceStore } from './device';

export const useGameStore = defineStore('game', () => {
  const gameData = ref(null);
  const gameStatus = ref(null);
  const winner = ref(null);
  const joinStatus = ref(null);
  const joinError = ref(null);
  const pollingInterval = ref(null);
  const gameId = ref(null);

  const deviceStore = useDeviceStore();

  const currentPlayerColor = computed(() => {
    if (!gameData.value || !deviceStore.getFingerprint) return null;
    if (gameData.value.white_player_fingerprint === deviceStore.getFingerprint) return 'w';
    if (gameData.value.black_player_fingerprint === deviceStore.getFingerprint) return 'b';
    return null;
  });

  async function startPolling() {
    if (pollingInterval.value) clearInterval(pollingInterval.value);
    if (!gameId.value) {
        console.error('Не могу начать polling: gameId не установлен.');
        return;
    }
    pollingInterval.value = setInterval(async () => {
      try {
        await fetchGame(gameId.value);
      } catch (e) {
        console.error('Ошибка polling:', e);
        if (e.message === 'not_found') {
            stopPolling();
        }
      }
    }, 1000);
  }

  function stopPolling() {
    if (pollingInterval.value) {
      clearInterval(pollingInterval.value);
      pollingInterval.value = null;
      console.log('Polling stopped.');
    }
  }

  async function fetchGame(uuid) {
    if (gameId.value !== uuid) {
        resetGame();
        gameId.value = uuid;
    }
    if (!gameId.value) {
        console.error('Не могу загрузить игру: uuid не установлен.');
        return;
    }
    try {
      const response = await api.get(`/games/${gameId.value}`);
      gameData.value = response.data;

      if (gameData.value.state !== 'waiting_for_player' && gameData.value.state !== 'in_progress') {
           stopPolling();
      }

      if (gameData.value.state === 'waiting_for_player' && !currentPlayerColor.value) {
        await joinGame(gameId.value);
      }

    } catch (error) {
      console.error('Ошибка при загрузке игры:', error);
      if (error.response && error.response.status === 404) {
        stopPolling();
        throw new Error('not_found');
      }
      stopPolling();
      throw error;
    }
  }

  async function joinGame(uuid) {
     if (!gameId.value) gameId.value = uuid;

    joinStatus.value = 'pending';
    const fingerprint = deviceStore.getFingerprint;
    if (!fingerprint || fingerprint === 'unknown') {
      joinStatus.value = 'failed';
      joinError.value = 'Отпечаток устройства не загружен.';
      stopPolling();
      return;
    }
    try {
      const response = await api.post(`/games/${gameId.value}/join`, { fingerprint });
      gameData.value = response.data;
      joinStatus.value = null;
    } catch (error) {
      joinStatus.value = 'failed';
      joinError.value = error.response?.data?.error || error.message || 'Неизвестная ошибка сети.';
      console.error('Ошибка при выполнении запроса присоединения:', error);
      stopPolling();
    }
  }

  async function updateGame(uuid, fen) {
     if (!gameId.value) gameId.value = uuid;

    const fingerprint = deviceStore.getFingerprint;
    if (!fingerprint || fingerprint === 'unknown') return;
    try {
      const response = await api.put(`/games/${gameId.value}`, {
        game: { fen },
        fingerprint,
      });
      if (response.data) {
        gameData.value = response.data;
      }
    } catch (error) {
      console.error('Ошибка при обновлении игры:', error);
      throw error;
    }
  }

  async function resignGame(uuid) {
     if (!gameId.value) gameId.value = uuid;

    if (!gameData.value || gameData.value.state !== 'in_progress' || !currentPlayerColor.value) return;
    const fingerprint = deviceStore.getFingerprint;
    if (!fingerprint || fingerprint === 'unknown') return;
    const resignationState = currentPlayerColor.value === 'w' ? 'white_resigns' : 'black_resigns';
    try {
      const response = await api.put(`/games/${gameId.value}`, {
        game: { state: resignationState },
        fingerprint,
      });
      if (response.data) {
        gameData.value = response.data;
        stopPolling();
      }
    } catch (error) {
      console.error('Ошибка при сдаче игры:', error);
      throw error;
    }
  }

  function resetGame() {
    gameData.value = null;
    gameStatus.value = null;
    winner.value = null;
    joinStatus.value = null;
    joinError.value = null;
    gameId.value = null;
    stopPolling();
  }

  watch(() => gameData.value?.state, (newState) => {
      if (newState && newState !== 'waiting_for_player' && newState !== 'in_progress') {
          stopPolling();
      }
  });

   watch(() => joinStatus.value, (newJoinStatus) => {
        if (newJoinStatus === 'failed') {
             stopPolling();
        }
   });

  return {
    gameData,
    gameStatus,
    winner,
    joinStatus,
    joinError,
    gameId,
    currentPlayerColor,
    fetchGame,
    joinGame,
    updateGame,
    resignGame,
    resetGame,
    startPolling,
    stopPolling,
  };
});
