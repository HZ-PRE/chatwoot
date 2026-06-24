class AutoAssignment::MessageReplyAssignmentService
  pattr_initialize [:message!]

  def perform
    return unless outgoing_user_message?
    return unless conversation.inbox.enable_auto_assignment?

    Rails.logger.info(
      "[AUTO_ASSIGNMENT_REPLY] message_id=#{message.id} conversation_id=#{conversation.id} sender_id=#{message.sender_id} assignment_type=#{assignment_type}"
    )

    case assignment_type
    when 'first_reply'
      assign_on_first_reply
    when 'last_reply'
      assign_on_last_reply
    else
      Rails.logger.info(
        "[AUTO_ASSIGNMENT_REPLY] message_id=#{message.id} conversation_id=#{conversation.id} action=skip reason=unsupported_assignment_type"
      )
    end
  end

  private

  def assign_on_first_reply
    unless first_outgoing_reply?
      Rails.logger.info(
        "[AUTO_ASSIGNMENT_REPLY] message_id=#{message.id} conversation_id=#{conversation.id} action=skip reason=not_first_reply"
      )
      return
    end

    assign_to_sender('first_reply')
  end

  def assign_on_last_reply
    assign_to_sender('last_reply')
  end

  def assign_to_sender(strategy)
    unless assignable_sender?
      Rails.logger.info(
        "[AUTO_ASSIGNMENT_REPLY] message_id=#{message.id} conversation_id=#{conversation.id} action=skip reason=sender_not_assignable sender_id=#{message.sender_id} sender_type=#{message.sender_type} assignable_agent_ids=#{assignable_agent_ids.inspect}"
      )
      return
    end

    Rails.logger.info(
      "[AUTO_ASSIGNMENT_REPLY] message_id=#{message.id} conversation_id=#{conversation.id} strategy=#{strategy} assigning_to=#{message.sender_id}"
    )

    conversation.update(assignee: message.sender)
  end

  def first_outgoing_reply?
    conversation.messages.outgoing.where(sender_type: 'User').where.not(id: message.id).none?
  end

  def assignable_sender?
    return false unless message.sender.present?
    return false unless message.sender_type == 'User'
    return false unless assignable_agent_ids.include?(message.sender_id)

    true
  end

  def outgoing_user_message?
    message.outgoing? && message.sender_type == 'User'
  end

  def assignment_type
    config = conversation.inbox.auto_assignment_config || {}
    config['assignment_type'] || 'round_robin'
  end

  def assignable_agent_ids
    @assignable_agent_ids ||= conversation.inbox.assignable_agents.map(&:id)
  end

  def conversation
    message.conversation
  end
end
