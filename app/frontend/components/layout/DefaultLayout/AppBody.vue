<template>
  <div class="app-body">
    <router-view />
  </div>
</template>

<script setup>
// Логика AppBody, если потребуется
</script>

<style scoped>
.app-body {
  flex-grow: 1; /* Позволяет занимать доступное пространство */
  /* Высота будет calc(100vh - 60px) за счет стилей в DefaultLayout */
  margin-top: 60px; /* Отступ сверху, равный высоте топбара */
  min-height: calc(100vh - 60px); /* Гарантируем минимальную высоту */
  width: 100%; /* Занимает всю доступную ширину */
  box-sizing: border-box; /* Учитываем padding в размере */
  /* Возможно, потребуется padding или другие стили для внутреннего содержимого */
}
</style>
