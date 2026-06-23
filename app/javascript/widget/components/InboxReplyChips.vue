<script>
import configMixin from 'widget/mixins/configMixin';

const getFirstPresentValue = (source, keys) => {
  if (!source || typeof source !== 'object') {
    return '';
  }

  const value = keys.map(key => source[key]).find(item => item != null);
  return value == null ? '' : String(value).trim();
};

const parseChips = chips => {
  if (Array.isArray(chips)) {
    return chips;
  }

  if (typeof chips === 'string' && chips.trim()) {
    try {
      const parsedChips = JSON.parse(chips);
      return Array.isArray(parsedChips) ? parsedChips : [];
    } catch {
      return [];
    }
  }

  return [];
};

const normalizeChips = chips =>
  parseChips(chips)
    .map(chip => {
      const label = getFirstPresentValue(chip, ['label', 'title', 'name']);
      const replyText = getFirstPresentValue(chip, [
        'replyText',
        'reply_text',
        'text',
        'content',
        'message',
        'value',
        'title',
        'label',
      ]);

      return {
        ...chip,
        label,
        replyText,
      };
    })
    .filter(chip => chip.label && chip.replyText);

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
      return normalizeChips(this.channelConfig.replyChips);
    },
    hasReplyChips() {
      return this.replyChips.length > 0;
    },
  },
  methods: {
    onClickChip(chip) {
      if (!chip.replyText) {
        return;
      }
      this.onSendMessage(chip.replyText);
    },
  },
};
</script>

<template>
  <div>
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
  </div>
</template>
