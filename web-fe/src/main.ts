import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import { initializeI18n } from './i18n'
import router from './router'
import './styles/tokens.css'
import './styles/global.css'
import './styles/layout.css'
import './styles/anatomy.css'
import './styles/atlas.css'
import './styles/detail.css'
import './styles/plancreator.css'
import './styles/analysis.css'

const i18n = await initializeI18n()
createApp(App).use(createPinia()).use(i18n).use(router).mount('#app')
