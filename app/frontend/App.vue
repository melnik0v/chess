<template>
  <DefaultLayout />
</template>

<script setup>
import { onMounted } from 'vue';
import DefaultLayout from '@/components/layout/DefaultLayout/DefaultLayout.vue';
import { useDeviceStore } from '@/stores/device';

const deviceStore = useDeviceStore();

onMounted(() => {
  deviceStore.loadFingerprint();
});

</script>

<style>
html, body {
  margin: 0;
  padding: 0;
  overflow: hidden;
}

#app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

</style>

<style scoped>
</style>
