<script setup lang="ts">
import { computed } from 'vue'
import DOMPurify from 'dompurify'
import { marked } from 'marked'

const props = defineProps<{ markdown: string }>()
const html = computed(() => {
  const parsed = marked.parse(props.markdown, { async: false }) as string
  const sanitized = DOMPurify.sanitize(parsed, { USE_PROFILES: { html: true } })
  const documentNode = new DOMParser().parseFromString(sanitized, 'text/html')
  documentNode.querySelectorAll<HTMLAnchorElement>('a[href]').forEach((anchor) => {
    if (/^https?:\/\//i.test(anchor.href)) {
      anchor.target = '_blank'
      anchor.rel = 'noopener noreferrer'
    }
  })
  return documentNode.body.innerHTML
})
</script>

<template>
  <article class="markdown-article" v-html="html" />
</template>
