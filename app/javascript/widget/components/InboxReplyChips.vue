<script>
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'InboxReplyChips',
  mixins: [configMixin],
  props: {
    onSendMessage: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    replyChips() {
      const chips = this.channelConfig.replyChips;

      if (Array.isArray(chips)) {
        return chips.filter(chip => chip?.label && chip?.replyText);
      }

      if (typeof chips === 'string') {
        try {
          const parsedChips = JSON.parse(chips);
          return Array.isArray(parsedChips)
            ? parsedChips.filter(chip => chip?.label && chip?.replyText)
            : [];
        } catch {
          return [];
        }
      }

      return [];
    },
    hasReplyChips() {
      return this.replyChips.length > 0;
    },
  },
  methods: {
    onClickChip(chip) {
      this.onSendMessage(chip.replyText);
    },
  },
};
</script>

<template>
  <div v-if="hasReplyChips" class="px-4 pt-2 pb-1 bg-transparent">
    <div class="flex flex-wrap gap-2 justify-start">
      <button
        v-for="chip in replyChips"
        :key="chip.id || chip.label"
        type="button"
        class="max-w-full px-4 py-2 text-sm leading-5 text-left transition bg-white border rounded-full shadow-sm text-n-slate-12 border-n-slate-3 hover:bg-n-slate-1 dark:bg-n-solid-2 dark:border-n-solid-3 dark:text-n-slate-12 dark:hover:bg-n-solid-3"
        @click="onClickChip(chip)"
      >
        <span class="break-words">{{ chip.label }}</span>
      </button>
    </div>
  </div>
</template>
