import React from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import {
  Card,
  CardBody,
  Grid,
  GridItem,
  FormGroup,
  Select,
  SelectList,
  SelectOption,
  MenuToggle,
  Tooltip,
  CardHeader,
  CardTitle,
} from '@patternfly/react-core';
import DateTimeField from './DateTimeField';

const SCCTokenRefreshCard = ({
  interval,
  intervalOptions,
  openInterval,
  refreshDate,
  refreshTime,
  onIntervalChange,
  onIntervalOpenChange,
  onRefreshDateChange,
  onRefreshTimeChange,
}) => (
  <Card isFlat ouiaId="scc-token-refresh-card">
    <CardHeader ouiaId="scc-token-refresh-card-header">
      <CardTitle
        component="h2"
        className="pf-v5-u-font-size-xl pf-v5-u-mt-0"
        ouiaId="scc-token-refresh-card-title"
      >
        {__('Token Refresh Settings')}
      </CardTitle>
    </CardHeader>
    <CardBody ouiaId="scc-token-refresh-card-body">
      <Grid hasGutter ouiaId="scc-token-refresh-grid">
        <GridItem sm={6} md={6} lg={6} ouiaId="scc-interval-grid-item">
          <FormGroup
            label={
              <Tooltip
                content={__(
                  'The token refresh interval is used to periodically update the SCC authentication tokens of any imported products.'
                )}
                ouiaId="scc-interval-tooltip"
              >
                <span>{__('Refresh interval')}</span>
              </Tooltip>
            }
            fieldId="scc-interval"
            ouiaId="scc-interval-form-group"
          >
            <Select
              id="scc-interval"
              isOpen={openInterval}
              selected={interval}
              onSelect={(_, val) => {
                onIntervalChange(String(val));
                onIntervalOpenChange(false);
              }}
              onOpenChange={onIntervalOpenChange}
              ouiaId="scc-interval-select"
              toggle={(ref) => (
                <MenuToggle
                  ref={ref}
                  isExpanded={openInterval}
                  isFullWidth
                  onClick={() => onIntervalOpenChange(!openInterval)}
                  ouiaId="scc-interval-menu-toggle"
                >
                  {interval}
                </MenuToggle>
              )}
            >
              <SelectList ouiaId="scc-interval-select-list">
                {intervalOptions.map((option, i) => (
                  <SelectOption
                    key={i}
                    value={String(option)}
                    ouiaId={`scc-interval-option-${i}`}
                  >
                    {String(option)}
                  </SelectOption>
                ))}
              </SelectList>
            </Select>
          </FormGroup>
        </GridItem>

        <GridItem sm={6} md={6} lg={6} ouiaId="scc-refresh-time-grid-item">
          <div className="pf-v5-u-w-100">
            <DateTimeField
              id="scc-refresh-time"
              label={
                <Tooltip
                  content={__(
                    'Specifies the daily time when the SCC authentication token refresh process starts. Set this to a time outside of business hours (e.g., during the night) to minimize disruption.'
                  )}
                  ouiaId="scc-refresh-time-tooltip"
                >
                  <span>{__('Refresh time')}</span>
                </Tooltip>
              }
              date={refreshDate}
              time={refreshTime}
              onDateChange={onRefreshDateChange}
              onTimeChange={onRefreshTimeChange}
            />
          </div>
        </GridItem>
      </Grid>
    </CardBody>
  </Card>
);

SCCTokenRefreshCard.propTypes = {
  interval: PropTypes.string.isRequired,
  intervalOptions: PropTypes.arrayOf(PropTypes.string).isRequired,
  openInterval: PropTypes.bool.isRequired,
  refreshDate: PropTypes.string.isRequired,
  refreshTime: PropTypes.string.isRequired,
  onIntervalChange: PropTypes.func.isRequired,
  onIntervalOpenChange: PropTypes.func.isRequired,
  onRefreshDateChange: PropTypes.func.isRequired,
  onRefreshTimeChange: PropTypes.func.isRequired,
};

export default SCCTokenRefreshCard;
