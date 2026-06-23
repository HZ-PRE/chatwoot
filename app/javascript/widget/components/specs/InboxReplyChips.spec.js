import { mount } from '@vue/test-utils';
import InboxReplyChips from '../InboxReplyChips.vue';

const mountComponent = ({ replyChips, onSendMessage = vi.fn() } = {}) => {
  window.chatwootWebChannel = {
    enabledFeatures: [],
    replyChips,
  };

  return {
    wrapper: mount(InboxReplyChips, {
      props: { onSendMessage },
    }),
    onSendMessage,
  };
};

describe('InboxReplyChips', () => {
  afterEach(() => {
    delete window.chatwootWebChannel;
  });

  it('normalizes reply chip labels and reply text from supported field names', () => {
    const { wrapper } = mountComponent({
      replyChips: [
        { label: '售前咨询', replyText: '我想了解价格' },
        { title: '售后服务', reply_text: '我需要售后帮助' },
        { name: '人工客服', text: '转人工客服' },
        { label: '发票', content: '我想开发票' },
        { label: '订单', message: '查询订单' },
        { label: '只配置标签时发送标签文字' },
      ],
    });

    expect(wrapper.vm.replyChips).toEqual([
      expect.objectContaining({ label: '售前咨询', replyText: '我想了解价格' }),
      expect.objectContaining({
        label: '售后服务',
        replyText: '我需要售后帮助',
      }),
      expect.objectContaining({ label: '人工客服', replyText: '转人工客服' }),
      expect.objectContaining({ label: '发票', replyText: '我想开发票' }),
      expect.objectContaining({ label: '订单', replyText: '查询订单' }),
      expect.objectContaining({
        label: '只配置标签时发送标签文字',
        replyText: '只配置标签时发送标签文字',
      }),
    ]);
  });

  it('parses JSON string config and sends the selected reply text on click', async () => {
    const { wrapper, onSendMessage } = mountComponent({
      replyChips: JSON.stringify([
        { label: '标签', value: '标签对应的文字内容' },
      ]),
    });

    await wrapper.find('button').trigger('click');

    expect(onSendMessage).toHaveBeenCalledWith('标签对应的文字内容');
  });

  it('does not render invalid chip config', () => {
    const { wrapper } = mountComponent({
      replyChips: [{ label: '' }, { foo: 'bar' }, 'invalid'],
    });

    expect(wrapper.find('button').exists()).toBe(false);
  });
});
