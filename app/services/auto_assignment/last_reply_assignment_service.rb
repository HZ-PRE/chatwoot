class AutoAssignment::LastReplyAssignmentService
  # Assigns conversation to the agent who last replied in the conversation history
  # Falls back to round-robin if no previous replies exist
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    agent_id = last_reply_agent_id
    return inbox_member(agent_id) if agent_id.present?

    round_robin_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  private

  def last_reply_agent_id
    replies = outgoing_replies_ordered
    return nil if replies.blank?

    # Find the agent who sent the last outgoing reply that matches allowed agents
    replies.reverse.each do |message|
      next unless allowed_agent_ids.include?(message.sender_id)

      return message.sender_id
    end
    nil
  end

  def outgoing_replies_ordered
    conversation.messages.outgoing.order(created_at: :asc)
  end

  def allowed_online_agent_ids
    online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def round_robin_service
    @round_robin_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  end

  def inbox_member(user_id)
    conversation.inbox.inbox_members.find_by(user_id: user_id)&.user
  end
end
