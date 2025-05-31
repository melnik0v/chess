<template>
  <div class="app-topbar">
    <div class="topbar-start">
      <router-link to="/" class="app-title">choss</router-link>
    </div>
    <div class="topbar-center">
      <template v-if="gameStore.gameData">
        <div v-if="gameStore.gameData.state">Состояние игры: {{ gameStore.gameData.state }}</div>
        <div class="current-game-color-data" v-if="gameStore.currentPlayerColor">Ваш цвет: <span :class="['current-game-color', gameStore.currentPlayerColorFull]"></span></div>
        <div v-if="gameStore.gameData.turn">Ход: {{ gameStore.gameData.turn === 'w' ? 'Белых' : 'Черных' }}</div>
      </template>
    </div>
    <div class="topbar-end">
      <template v-if="isAuthenticated">
        <Button label="Создать игру" @click="showColorDialog" class="p-button-text mr-2" />
        <Button label="Выйти" @click="logout" class="p-button-text" />
      </template>
      <template v-else>
        <router-link to="/sign-in"><Button label="Войти" class="p-button-text mr-2" /></router-link>
        <router-link to="/sign-up"><Button label="Регистрация" class="p-button-outlined" /></router-link>
      </template>
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
import { useAuthStore } from '@/stores/auth';
import { useGameStore } from '@/stores/game';
import api from '@/config/api'; // Импортируем настроенный api клиент

const router = useRouter();
const authStore = useAuthStore();
const gameStore = useGameStore();

const isAuthenticated = computed(() => authStore.isAuthenticated);
const userEmail = computed(() => authStore.user ? authStore.user.email : '');

const displayColorDialog = ref(false);
const chosenColor = ref(null);

const showColorDialog = () => {
  displayColorDialog.value = true;
};

const hideColorDialog = () => {
  displayColorDialog.value = false;
  chosenColor.value = null; // Сброс выбора цвета при отмене
};

// Выход из системы
const logout = () => {
  authStore.logout();
  router.push('/sign-in'); // Перенаправление на страницу входа после выхода
};

// Функция для создания игры
const createGame = async () => {
  console.log('Attempting to create game with color:', chosenColor.value);
  if (!chosenColor.value) {
    console.log('No color chosen, game not created.');
    return; // Не создаем игру, если цвет не выбран
  }

  try {
    console.log('Sending request to /api/v1/games with color:', chosenColor.value);
    const response = await api.post('/games', {
      chosen_color: chosenColor.value,
    });
    const { game_id, invitation_token } = response.data;

    console.log('Игра создана:', { game_id, invitation_token });
    router.push({ name: 'GamePage', params: { id: game_id } }); // Перенаправить на страницу игры
    hideColorDialog(); // Закрыть диалог после создания игры
  } catch (error) {
    console.error('Ошибка при создании игры:', error);
    // TODO: Обработать ошибку, показать сообщение пользователю
    hideColorDialog(); // Закрыть диалог даже в случае ошибки
  }
};

// Проверяем статус авторизации при монтировании компонента (вызываем fetchUser из стора)
// authStore.fetchUser(); // Удаляем этот вызов

// В реальном приложении нужно будет слушать изменения статуса авторизации
// Например, через централизованное хранилище (Vuex, Pinia)

</script>

<style scoped>
.app-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 20px;
  background-color: #2a2a2a; /* Пример цвета фона */
  color: #cacaca; /* Пример цвета текста */
  /* Добавляем стили для фиксации */
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 1000; /* Убедимся, что топбар находится поверх другого контента */
  height: 60px; /* Устанавливаем фиксированную высоту */
}

.topbar-start,
.topbar-end {
  /* flex-basis: 0; /* Позволяет этим блокам сжиматься */
  flex-shrink: 0; /* Предотвращает сжатие меньше содержимого */
}

.topbar-center {
  flex-grow: 1; /* Позволяет блоку занимать все доступное пространство */
  text-align: center; /* Центрируем текст */
  /* Дополнительные стили для выравнивания содержимого внутри */
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px; /* Добавляем расстояние между элементами информации */
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
