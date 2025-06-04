<template>
  <div class="dashboard-content">
    <h2>Выберите цвет для игры:</h2>
    <div class="color-selection">
      <Button label="Играть белыми" @click="createGame('white')" class="color-button white-button" />
      <Button label="Играть черными" @click="createGame('black')" class="color-button black-button" />
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router';
import Button from 'primevue/button';
import { useDeviceStore } from '@/stores/device';
import api from '@/config/api';

const router = useRouter();
const deviceStore = useDeviceStore();

const createGame = async (chosenColor) => {
  const fingerprint = deviceStore.getFingerprint;

  if (!fingerprint || fingerprint === 'unknown') {
    console.error('Отпечаток устройства не загружен.');

    return;
  }

  try {
    const response = await api.post('/games', {
      fingerprint: fingerprint,
      chosen_color: chosenColor,
    });

    const gameData = response.data;
    console.log('Игра создана:', gameData);

    router.push({ name: 'GamePage', params: { uuid: gameData.uuid } });

  } catch (error) {
    console.error('Ошибка запроса:', error);
  }
};
</script>

<style scoped>
.dashboard-content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 60px);
  text-align: center;
}

.color-selection {
  margin-top: 20px;
  display: flex;
  gap: 20px;
}

.color-button {
  font-size: 1.2em;
  padding: 10px 20px;
}

.white-button {

}

.black-button {

}
</style>
