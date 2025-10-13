import React from 'react';
import PropTypes from 'prop-types';
import {
  FormGroup,
  InputGroup,
  DatePicker,
  TimePicker,
} from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';

export const formatDateTime = (dateStr, timeStr) => {
  if (!dateStr || !timeStr) return undefined;

  const match = timeStr.match(/^(\d{1,2}):(\d{2})\s*([AP]M)$/i);
  if (!match) return undefined;

  const [, hourStr, minuteStr, ampm] = match;
  const hour24 =
    (parseInt(hourStr, 10) % 12) + (ampm.toUpperCase() === 'PM' ? 12 : 0);

  const [year, month, day] = dateStr.split('-').map(Number);
  if (!year || !month || !day) return undefined;

  const date = new Date(
    year,
    month - 1,
    day,
    hour24,
    parseInt(minuteStr, 10),
    0,
    0
  );
  return Number.isNaN(date.getTime()) ? undefined : date.toISOString();
};

const DateTimeField = ({
  id,
  label,
  date,
  time,
  onDateChange,
  onTimeChange,
}) => (
  <FormGroup label={label} fieldId={id} ouiaId={`${id}-form-group`}>
    <InputGroup ouiaId={`${id}-input-group`}>
      <DatePicker
        value={date}
        onChange={(_, val) => onDateChange(val)}
        placeholder={__('YYYY-MM-DD')}
        ouiaId={`${id}-date-picker`}
      />
      <TimePicker
        id={`${id}-time`}
        time={time}
        onChange={(_e, timeStr) => onTimeChange(timeStr)}
        placeholder={__('HH:MM AM')}
        ouiaId={`${id}-time-picker`}
      />
    </InputGroup>
  </FormGroup>
);

DateTimeField.propTypes = {
  id: PropTypes.string.isRequired,
  label: PropTypes.node.isRequired,
  date: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  onDateChange: PropTypes.func.isRequired,
  onTimeChange: PropTypes.func.isRequired,
};

export default DateTimeField;
