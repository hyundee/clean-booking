import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // /api 요청을 백엔드로 전달해 같은 출처처럼 동작
    proxy: {
      '/api': 'http://localhost:8080',
    },
  },
})
