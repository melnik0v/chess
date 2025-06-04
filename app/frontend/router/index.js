import { createRouter, createWebHistory } from 'vue-router';
// Удаляем импорты Register и Login
// import Home from '../views/Home.vue'; // Home, вероятно, больше не нужен, если главная - Dashboard
// import Register from '../views/auth/Register.vue';
// import Login from '../views/auth/Login.vue';
import GamePage from '../views/GamePage.vue';

const routes = [
  {
    path: '/',
    name: 'Home', // Возможно, переименовать в Dashboard
    component: () => import('../views/Dashboard.vue'),
  },
  // Удаляем маршруты регистрации и входа
  // {
  //   path: '/sign-up',
  //   name: 'Register',
  //   component: Register,
  // },
  // {
  //   path: '/sign-in',
  //   name: 'Login',
  //   component: Login,
  // },
  {
    // Изменяем путь для использования UUID
    path: '/games/:uuid',
    name: 'GamePage',
    component: GamePage,
    props: true,
  },
  // Маршрут для присоединения через ссылку теперь не нужен,
  // так как логика присоединения интегрирована в GamePage
  // {
  //   path: '/games/join/:invitationToken',
  //   name: 'JoinGamePage',
  //   component: () => import('../views/JoinGamePage.vue'),
  //   props: true,
  // },
  // Добавьте другие маршруты здесь
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
