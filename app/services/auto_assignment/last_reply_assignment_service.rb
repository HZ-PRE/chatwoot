require 'set'

class AutoAssignment::LastReplyAssignmentService
  # Assigns conversation to the last agent who replied.
  # Priority:
  # 1. Last outgoing reply in the current conversation
  # 2. Last outgoing reply across this contact's conversation history in the inbox
  # 3. Fallback to round-robin
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    agent = last_reply_agent
    return agent if agent.present?

    round_robin_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  private

  def last_reply_agent
    candidate_agent_id = current_conversation_last_reply_agent_id || historical_last_reply_agent_id
    return nil unless candidate_agent_id.present?
    return nil unless online_agent_id_set.include?(candidate_agent_id.to_s)

    inbox_member(candidate_agent_id)
  end

  def current_conversation_last_reply_agent_id
    matching_agent_id_from_messages(conversation.messages.outgoing.order(created_at: :desc))
  end

  def historical_last_reply_agent_id
    matching_agent_id_from_messages(historical_outgoing_messages.order(created_at: :desc))
  end

  def historical_outgoing_messages
    Message.where(conversation_id: historical_conversation_ids).outgoing
  end

  def historical_conversation_ids
    conversation.contact.conversations.where(inbox_id: conversation.inbox_id).where.not(id: conversation.id).select(:id)
  end

  def matching_agent_id_from_messages(messages)
    messages.each do |message|
      next unless allowed_agent_id_set.include?(message.sender_id)

      return message.sender_id
    end
    nil
  end

  def allowed_agent_id_set
    @allowed_agent_id_set ||= allowed_agent_ids.to_set
  end

  def allowed_online_agent_ids
    online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    return [] unless online_agents.present?

    online_agents.select { |_key, value| value.eql?('online') }.keys
  end

  def online_agent_id_set
    @online_agent_id_set ||= online_agent_ids.to_set
  end

  def round_robin_service
    @round_robin_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  end

  def inbox_member(user_id)
    conversation.inbox.inbox_members.find_by(user_id: user_id)&.user
  end
end
