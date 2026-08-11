import { fileURLToPath, URL } from 'node:url'

import vue from '@vitejs/plugin-vue'
import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const apiPort = env.MAMMOONE || '8000'
  const apiTarget = env.VITE_DEV_API_TARGET || `http://127.0.0.1:${apiPort}`

  return {
    plugins: [vue()],
    resolve: {
      alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
    },
    server: {
      proxy: {
        '/api': apiTarget,
        '/assets': apiTarget,
        '/media': apiTarget,
        '/health': apiTarget,
        '/docs': apiTarget,
        '/openapi.json': apiTarget,
      },
    },
  }
})
