<template>
  <div class="app-topbar">
    <div class="topbar-start">
      <router-link to="/" class="app-title">choss</router-link>
    </div>
    <div class="topbar-center">

    </div>
    <div class="topbar-end">
      <Button label="Создать игру" @click="showColorDialog" class="p-button-text mr-2" />
    </div>
  </div>

  <Dialog v-model:visible="displayColorDialog" header="Выберите цвет" modal :style="{ width: '300px' }">
    <div class="field-radiobutton">
      <RadioButton id="colorWhite" name="color" value="white" v-model="chosenColor" />
      <label for="colorWhite">Белые</label>
    </div>
    <div class="field-radiobutton">
      <RadioButton id="colorBlack" name="color" value="black" v-model="chosenColor" />
      <label for="colorBlack">Черные</label>
    </div>
    <template #footer>
      <Button label="Отмена" icon="pi pi-times" class="p-button-text" @click="hideColorDialog" />
      <Button label="Создать" icon="pi pi-check" autofocus @click="createGame" :disabled="!chosenColor" />
    </template>
  </Dialog>
</template>

<script setup>
import { ref, computed } from 'vue';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import RadioButton from 'primevue/radiobutton';
import { useRouter } from 'vue-router';
import api from '@/config/api';
import { useDeviceStore } from '@/stores/device';

const router = useRouter();
const deviceStore = useDeviceStore();


const displayColorDialog = ref(false);
const chosenColor = ref(null);

const showColorDialog = () => {
  displayColorDialog.value = true;
};

const hideColorDialog = () => {
  displayColorDialog.value = false;
  chosenColor.value = null;
};


const createGame = async () => {
  console.log('Attempting to create game with color:', chosenColor.value);
  const fingerprint = deviceStore.getFingerprint;

  if (!fingerprint || fingerprint === 'unknown') {
    console.error('Отпечаток устройства не загружен. Невозможно создать игру.');

    return;
  }

  if (!chosenColor.value) {
    console.log('No color chosen, game not created.');
    return;
  }

  try {
    console.log('Sending request to /api/v1/games with color:', chosenColor.value);
    const response = await api.post('/games', {
      fingerprint: fingerprint,
      chosen_color: chosenColor.value,
    });
    const { uuid } = response.data;

    console.log('Игра создана:', { uuid });
    router.push({ name: 'GamePage', params: { uuid: uuid } });
    hideColorDialog();
  } catch (error) {
    console.error('Ошибка при создании игры:', error);

    hideColorDialog();
  }
};
</script>

<style scoped>
.app-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 20px;
  background-color: #2a2a2a;
  color: #cacaca;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 1000;
  height: 60px;
}

.topbar-start,
.topbar-end {
  flex-shrink: 0;
}

.topbar-center {
  flex-grow: 1;
  text-align: center;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
}

.app-title {
  font-size: 1.5em;
  font-weight: bold;
  text-decoration: none;
  color: #e7e7e7;
}

.topbar-end {
  display: flex;
  align-items: center;
}

.current-game-color-data {
  display: flex;
  align-items: center;
  gap: 10px;
}

.current-game-color {
  display: inline-block;
  width: 25px;
  height: 25px;
  border-radius: 5px;
}

.current-game-color.black {
  background-color: #000000;
}

.current-game-color.white {
  background-color: #ffffff;
}
</style>
