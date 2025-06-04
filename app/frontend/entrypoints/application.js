import { createApp } from 'vue';
import App from '../App.vue';
import router from '../router';
import PrimeVue from 'primevue/config';
import Aura from '@primeuix/themes/aura';
import 'primeicons/primeicons.css';
import { createPinia } from 'pinia';

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(App);
  app.use(router);
  app.use(PrimeVue, { theme: { preset: Aura }});
  app.use(createPinia());
  app.mount('#app');
});
