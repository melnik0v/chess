<template>
  <DefaultLayout />
</template>

<script setup>
// Composition API тут
import DefaultLayout from '@/components/layout/DefaultLayout/DefaultLayout.vue';
</script>

<style>
/* Это глобальные стили */
html, body {
  margin: 0;
  padding: 0;
  overflow: hidden; /* Добавляем, чтобы избежать скроллбаров из-за 100vh */
}

#app {
  height: 100vh; /* Убедимся, что корневой элемент приложения занимает всю высоту */
  display: flex;
  flex-direction: column;
}

/* Глобальные стили, которые были раньше */
</style>

<style scoped>
/* Стили, специфичные для App.vue, если есть */
</style>
