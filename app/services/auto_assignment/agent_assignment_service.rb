class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  ASSIGNMENT_TYPES = %w[round_robin first_reply last_reply].freeze

  def find_assignee
    assignment_service.find_assignee
  end

  def perform
    Rails.logger.info(
      "[AUTO_ASSIGNMENT] service=agent_assignment conversation_id=#{conversation.id} inbox_id=#{conversation.inbox_id} " \
      "contact_id=#{conversation.contact_id} config=#{conversation.inbox.auto_assignment_config.inspect} " \
      "assignment_type=#{assignment_type} allowed_agent_ids=#{allowed_agent_ids.inspect}"
    )

    new_assignee = find_assignee

    Rails.logger.info(
      "[AUTO_ASSIGNMENT] service=agent_assignment conversation_id=#{conversation.id} selected_assignee_id=#{new_assignee&.id.inspect}"
    )

    conversation.update(assignee: new_assignee) if new_assignee
  end

  private

  def assignment_type
    config = conversation.inbox.auto_assignment_config || {}
    type = config['assignment_type'] || 'round_robin'
    ASSIGNMENT_TYPES.include?(type) ? type : 'round_robin'
  end

  def assignment_service
    case assignment_type
    when 'first_reply'
      AutoAssignment::FirstReplyAssignmentService.new(
        conversation: conversation,
        allowed_agent_ids: allowed_agent_ids
      )
    when 'last_reply'
      AutoAssignment::LastReplyAssignmentService.new(
        conversation: conversation,
        allowed_agent_ids: allowed_agent_ids
      )
    else
      round_robin_service
    end
  end

  def round_robin_service
    @round_robin_service ||= Struct.new(:conversation, :allowed_agent_ids) do
      def find_assignee
        svc = AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
        svc.available_agent(allowed_agent_ids: allowed_online_agent_ids)
      end

      def allowed_online_agent_ids
        online_ids = OnlineStatusTracker.get_available_users(conversation.account_id)
        online_ids = online_ids.select { |_k, v| v == 'online' }.keys if online_ids.present?
        online_ids & allowed_agent_ids&.map(&:to_s)
      end
    end.new(conversation, allowed_agent_ids)
  end
end
