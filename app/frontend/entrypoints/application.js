import { createApp } from 'vue';
import App from '../App.vue';
import router from '../router';
import PrimeVue from 'primevue/config';
import Aura from '@primeuix/themes/aura';
import 'primeicons/primeicons.css'; // Стили иконок
import { createPinia } from 'pinia';
import { useAuthStore } from '../stores/auth';

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(App);
  app.use(router);
  app.use(PrimeVue, {
    theme: {
      preset: Aura
    }
  });

  const pinia = createPinia();
  app.use(pinia);

  app.mount('#app');

  // Вызов fetchUser после монтирования приложения и инициализации Pinia
  const authStore = useAuthStore(); // Импортируем useAuthStore
  authStore.fetchUser();
});
