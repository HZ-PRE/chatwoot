import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_4,
  OPERATOR_TYPES_7,
} from 'dashboard/routes/dashboard/settings/automation/operators';
import {
  DEFAULT_MESSAGE_CREATED_CONDITION,
  DEFAULT_CONVERSATION_OPENED_CONDITION,
  DEFAULT_OTHER_CONDITION,
  DEFAULT_ACTIONS,
} from 'dashboard/constants/automation';
import filterQueryGenerator from './filterQueryGenerator';
import actionQueryGenerator from './actionQueryGenerator';

export const getCustomAttributeInputType = key => {
  const customAttributeMap = {
    date: 'date',
    text: 'plain_text',
    list: 'search_select',
    checkbox: 'search_select',
  };

  return customAttributeMap[key] || 'plain_text';
};

export const isACustomAttribute = (customAttributes, key) => {
  return customAttributes.find(attr => {
    return attr.attribute_key === key;
  });
};

export const getCustomAttributeListDropdownValues = (
  customAttributes,
  type
) => {
  return customAttributes
    .find(attr => attr.attribute_key === type)
    .attribute_values.map(item => {
      return {
        id: item,
        name: item,
      };
    });
};

export const isCustomAttributeList = (customAttributes, type) => {
  return customAttributes.some(attr => {
    return (
      attr.attribute_key === type && attr.attribute_display_type === 'list'
    );
  });
};

export const getOperatorTypes = key => {
  const operatorMap = {
    list: OPERATOR_TYPES_1,
    text: OPERATOR_TYPES_7,
    number: OPERATOR_TYPES_1,
    link: OPERATOR_TYPES_7,
    date: OPERATOR_TYPES_4,
    checkbox: OPERATOR_TYPES_1,
  };

  return operatorMap[key] || OPERATOR_TYPES_1;
};

export const generateCustomAttributeTypes = (customAttributes, type) => {
  return customAttributes.map(attr => {
    return {
      key: attr.attribute_key,
      name: attr.attribute_display_name,
      inputType: getCustomAttributeInputType(attr.attribute_display_type),
      filterOperators: getOperatorTypes(attr.attribute_display_type),
      customAttributeType: type,
    };
  });
};

const transformCustomAttribute = ({ key, name, customAttributeType }) => {
  return {
    key,
    name,
    inputType: 'plain_text',
    filterOperators: OPERATOR_TYPES_1,
    customAttributeType,
  };
};

export const transformCustomAttributes = customAttributes => {
  return {
    conversationAttributes: customAttributes.conversationAttributes.map(attr =>
      transformCustomAttribute({
        ...attr,
        customAttributeType: 'conversation_attribute',
      })
    ),
    contactAttributes: customAttributes.contactAttributes.map(attr =>
      transformCustomAttribute({
        ...attr,
        customAttributeType: 'contact_attribute',
      })
    ),
  };
};

export const getActionTypes = actionTypes => {
  return actionTypes.map(action => {
    return {
      key: action.key,
      name: action.name,
      inputType: action.inputType,
      inputOptions: action.inputOptions,
    };
  });
};

export const getConditionTypes = automationTypes => {
  return automationTypes.map(condition => {
    return {
      key: condition.key,
      name: condition.name,
      inputType: condition.inputType,
      filterOperators: condition.filterOperators,
      customAttributeType: condition.customAttributeType || '',
    };
  });
};

export const getConditionValueInputType = (customAttributes, type) => {
  if (type === 'status') return 'search_select';
  if (type === 'message_type') return 'search_select';
  if (type === 'assignee_id') return 'search_select';
  if (type === 'team_id') return 'search_select';
  if (type === 'priority') return 'search_select';
  if (type === 'conversation_status') return 'search_select';
  if (type === 'browser_language') return 'search_select';
  if (type === 'country_code') return 'search_select';
  if (type === 'referer') return 'search_select';
  if (type === 'mail_to') return 'search_select';
  if (type === 'label') return 'multi_select';
  if (type === 'campaign_id') return 'search_select';
  if (type === 'inbox_id') return 'search_select';
  if (type === 'phone_number') return 'plain_text';

  if (isCustomAttributeList(customAttributes, type)) {
    return 'search_select';
  }

  const customAttribute = isACustomAttribute(customAttributes, type);
  if (customAttribute) {
    return getCustomAttributeInputType(customAttribute.attribute_display_type);
  }

  return 'plain_text';
};

export const getConditionDropdownValues = (
  customAttributes,
  type,
  {
    statusFilterOptions = [],
    messageTypeFilterOptions = [],
    assigneeFilterOptions = [],
    teamFilterOptions = [],
    priorityFilterOptions = [],
    browserLanguageOptions = [],
    countryCodeOptions = [],
    refererOptions = [],
    mailToOptions = [],
    inboxFilterOptions = [],
    campaignFilterOptions = [],
    labelOptions = [],
  } = {}
) => {
  if (type === 'conversation_status') {
    return statusFilterOptions;
  }

  if (isCustomAttributeList(customAttributes, type)) {
    return getCustomAttributeListDropdownValues(customAttributes, type);
  }

  const conditionFilterMaps = {
    status: statusFilterOptions,
    message_type: messageTypeFilterOptions,
    assignee_id: assigneeFilterOptions,
    team_id: teamFilterOptions,
    priority: priorityFilterOptions,
    browser_language: browserLanguageOptions,
    country_code: countryCodeOptions,
    referer: refererOptions,
    mail_to: mailToOptions,
    inbox_id: inboxFilterOptions,
    campaign_id: campaignFilterOptions,
    label: labelOptions,
  };

  return conditionFilterMaps[type] || [];
};

export const getActionDropdownValues = (
  type,
  {
    assigneeFilterOptions = [],
    teamFilterOptions = [],
    inboxFilterOptions = [],
    labelOptions = [],
  } = {}
) => {
  const actionFilterMaps = {
    assign_team: teamFilterOptions,
    assign_agent: assigneeFilterOptions,
    add_label: labelOptions,
    remove_label: labelOptions,
    send_email_transcript: inboxFilterOptions,
  };

  return actionFilterMaps[type] || [];
};

export const getAutomationType = (automationTypes, automation, key) => {
  return automationTypes.find(item => {
    return item.key === (key || automation.attribute_key);
  });
};

export const getInputType = (
  customAttributes,
  automationTypes,
  automation,
  mode,
  key
) => {
  if (mode === 'edit') {
    const customAttribute = isACustomAttribute(customAttributes, key);
    if (customAttribute) {
      return getCustomAttributeInputType(
        customAttribute.attribute_display_type
      );
    }
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.inputType;
};

export const getOperators = (
  customAttributes,
  automationTypes,
  automation,
  mode,
  key
) => {
  if (mode === 'edit') {
    const customAttribute = isACustomAttribute(customAttributes, key);
    if (customAttribute) {
      return getOperatorTypes(customAttribute.attribute_display_type);
    }
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.filterOperators;
};

export const getCustomAttributeType = (
  automationTypes,
  automation,
  key,
  mode,
  customAttributes
) => {
  if (mode === 'edit') {
    const customAttribute = isACustomAttribute(customAttributes, key);
    if (customAttribute) {
      return automation.custom_attribute_type || '';
    }
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.customAttributeType || '';
};

export const generateAutomationPayload = automation => {
  return {
    ...automation,
    conditions: filterQueryGenerator(automation.conditions),
    actions: actionQueryGenerator(automation.actions),
  };
};

export const getDefaultConditions = eventName => {
  if (eventName === 'message_created') {
    return DEFAULT_MESSAGE_CREATED_CONDITION;
  }
  if (eventName === 'conversation_opened') {
    return DEFAULT_CONVERSATION_OPENED_CONDITION;
  }
  return DEFAULT_OTHER_CONDITION;
};

export const getDefaultActions = () => DEFAULT_ACTIONS;

export const getFileName = automation => {
  return automation.file ? automation.file.name : '';
};

export const showActionInput = (automationActionTypes, actionType) => {
  if (
    ['send_email_to_team', 'send_message', 'send_webhook_event'].includes(
      actionType
    )
  ) {
    return false;
  }

  const type = automationActionTypes.find(action => action.key === actionType);
  return !!type?.inputType;
};
