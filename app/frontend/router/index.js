import { createRouter, createWebHistory } from 'vue-router';
import Home from '../views/Home.vue';
import Register from '../views/auth/Register.vue';
import Login from '../views/auth/Login.vue';
import GamePage from '../views/GamePage.vue';

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/Dashboard.vue'),
  },
  {
    path: '/sign-up',
    name: 'Register',
    component: Register,
  },
  {
    path: '/sign-in',
    name: 'Login',
    component: Login,
  },
  {
    path: '/games/:id',
    name: 'GamePage',
    component: GamePage,
    props: true,
  },
  {
    path: '/games/join/:invitationToken',
    name: 'JoinGamePage',
    component: () => import('../views/JoinGamePage.vue'),
    props: true,
  },
  // Добавьте другие маршруты здесь
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
