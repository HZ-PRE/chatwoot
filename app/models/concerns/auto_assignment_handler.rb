module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_auto_assignment
  end

  private

  def run_auto_assignment
    Rails.logger.info(
      "[AUTO_ASSIGNMENT_TRIGGER] conversation_id=#{id} status=#{status} assignee_id=#{assignee_id.inspect} previous_changes=#{previous_changes.inspect}"
    )

    status_changed_to_open = conversation_status_changed_to_open?
    should_run = should_run_auto_assignment?

    Rails.logger.info(
      "[AUTO_ASSIGNMENT_TRIGGER] conversation_id=#{id} status_changed_to_open=#{status_changed_to_open} should_run_auto_assignment=#{should_run}"
    )

    unless status_changed_to_open
      Rails.logger.info(
        "[AUTO_ASSIGNMENT_TRIGGER] conversation_id=#{id} action=skip reason=status_not_changed_to_open"
      )
      return
    end

    unless should_run
      Rails.logger.info(
        "[AUTO_ASSIGNMENT_TRIGGER] conversation_id=#{id} action=skip reason=should_run_auto_assignment_false"
      )
      return
    end

    Rails.logger.info(
      "[AUTO_ASSIGNMENT_TRIGGER] conversation_id=#{id} action=perform_auto_assignment"
    )

    ::AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: inbox.member_ids_with_assignment_capacity).perform
  end

  def should_run_auto_assignment?
    return false unless inbox.enable_auto_assignment?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end
end
