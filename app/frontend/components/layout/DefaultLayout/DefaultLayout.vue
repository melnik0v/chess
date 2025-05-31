<template>
  <div class="default-layout">
    <AppTopbar />
    <AppBody />
  </div>
</template>

<script setup>
import AppTopbar from '@/components/layout/AppTopbar.vue';
import AppBody from './AppBody.vue';
</script>

<style scoped>
.default-layout {
  display: flex;
  flex-direction: column;
  min-height: 100vh; /* Убедимся, что макет занимает минимум всю высоту вьюпорта */
}
</style>
