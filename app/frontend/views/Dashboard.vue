<template>
  <div class="dashboard-content">
    <!-- Удаляем ChessBoard с главной страницы -->
    <!-- <ChessBoard /> -->
    <Button label="Создать игру" class="create-game-button" />
  </div>
</template>

<script setup>
// Удаляем импорт ChessBoard
// import ChessBoard from '../components/ChessBoard.vue';
import Button from 'primevue/button'; // Добавляем импорт компонента Button
</script>

<style scoped>
.dashboard-content {
  padding: 20px;
  display: flex;
  justify-content: center; /* Центрируем содержимое по горизонтали */
  align-items: center; /* Центрируем содержимое по вертикали */
  min-height: calc(100vh - 60px); /* Убедимся, что контейнер занимает всю доступную высоту (за вычетом топбара) */
}

.create-game-button {
  font-size: 1.5em; /* Увеличиваем размер шрифта для большой кнопки */
  padding: 15px 30px; /* Увеличиваем отступы для большой кнопки */
}
</style>
