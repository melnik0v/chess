import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import VueDevTools from 'vite-plugin-vue-devtools'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
    VueDevTools()
  ],
  resolve: {
    alias: {
      '@': `${process.cwd()}/app/frontend`,
    },
  },
})
