import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import './styles/tokens.css'
import './styles/global.css'
import './styles/layout.css'
import './styles/anatomy.css'
import './styles/atlas.css'
import './styles/detail.css'
import './styles/plancreator.css'
import './styles/analysis.css'

createApp(App).use(createPinia()).use(router).mount('#app')
