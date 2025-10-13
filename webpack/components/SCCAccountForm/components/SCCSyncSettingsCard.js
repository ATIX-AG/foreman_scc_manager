import React from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import {
  Card,
  CardTitle,
  CardBody,
  Grid,
  GridItem,
  FormGroup,
  Select,
  SelectList,
  SelectOption,
  MenuToggle,
  CardHeader,
  Tooltip,
} from '@patternfly/react-core';

const SCCSyncSettingsCard = ({
  gpgKey,
  gpgKeyOptions,
  openGpg,
  downloadPolicy,
  downloadPolicyOptions,
  openDownload,
  mirroringPolicy,
  mirroringPolicyOptions,
  openMirroring,
  onGpgKeyChange,
  onGpgOpenChange,
  onDownloadPolicyChange,
  onDownloadOpenChange,
  onMirroringPolicyChange,
  onMirroringOpenChange,
}) => (
  <Card isFlat ouiaId="scc-sync-settings-card">
    <CardHeader ouiaId="scc-sync-settings-card-header">
      <CardTitle
        component="h2"
        className="pf-v5-u-font-size-xl pf-v5-u-mt-0"
        ouiaId="scc-sync-settings-card-title"
      >
        {__('Repository Sync Settings')}
      </CardTitle>
    </CardHeader>
    <CardBody ouiaId="scc-sync-settings-card-body">
      <Grid hasGutter ouiaId="scc-sync-settings-grid">
        <GridItem md={4} lg={4} sm={4} ouiaId="scc-gpg-key-grid-item">
          <FormGroup
            label={
              <Tooltip
                content={__(
                  "Use this setting if you want to automatically add a GPG key to your SUSE products upon subscription. You can change this setting in the 'Content' > 'Products' menu, later."
                )}
                ouiaId="scc-gpg-key-tooltip"
              >
                <span>{__('GPG key for SUSE products')}</span>
              </Tooltip>
            }
            fieldId="scc-gpg"
            ouiaId="scc-gpg-key-form-group"
          >
            <Select
              id="scc-gpg"
              isOpen={openGpg}
              selected={gpgKey}
              onSelect={(_, v) => {
                onGpgKeyChange(String(v));
                onGpgOpenChange(false);
              }}
              onOpenChange={onGpgOpenChange}
              ouiaId="scc-gpg-key-select"
              toggle={(ref) => (
                <MenuToggle
                  ref={ref}
                  isExpanded={openGpg}
                  isFullWidth
                  onClick={() => onGpgOpenChange(!openGpg)}
                  ouiaId="scc-gpg-key-menu-toggle"
                >
                  {gpgKey || __('None')}
                </MenuToggle>
              )}
            >
              <SelectList ouiaId="scc-gpg-key-select-list">
                {gpgKeyOptions.length > 0 ? (
                  gpgKeyOptions.map(([label], index) => (
                    <SelectOption
                      key={index}
                      value={String(label)}
                      ouiaId={`scc-gpg-key-option-${index}`}
                    >
                      {String(label)}
                    </SelectOption>
                  ))
                ) : (
                  <SelectOption value="" ouiaId="scc-gpg-key-option-none">
                    {__('None')}
                  </SelectOption>
                )}
              </SelectList>
            </Select>
          </FormGroup>
        </GridItem>

        <GridItem md={4} lg={4} sm={4} ouiaId="scc-download-policy-grid-item">
          <FormGroup
            label={
              <Tooltip
                content={__(
                  'The default download policy for repositories which were created using this SCC Account.'
                )}
                ouiaId="scc-download-policy-tooltip"
              >
                <span>{__('Download Policy')}</span>
              </Tooltip>
            }
            fieldId="scc-download-policy"
            ouiaId="scc-download-policy-form-group"
          >
            <Select
              id="scc-download-policy"
              isOpen={openDownload}
              selected={downloadPolicy}
              onSelect={(_, val) => {
                onDownloadPolicyChange(String(val));
                onDownloadOpenChange(false);
              }}
              onOpenChange={onDownloadOpenChange}
              ouiaId="scc-download-policy-select"
              toggle={(ref) => (
                <MenuToggle
                  ref={ref}
                  isExpanded={openDownload}
                  onClick={() => onDownloadOpenChange(!openDownload)}
                  isFullWidth
                  ouiaId="scc-download-policy-menu-toggle"
                >
                  {downloadPolicy}
                </MenuToggle>
              )}
            >
              <SelectList ouiaId="scc-download-policy-select-list">
                {downloadPolicyOptions.map(([label], index) => (
                  <SelectOption
                    key={index}
                    value={String(label)}
                    ouiaId={`scc-download-policy-option-${index}`}
                  >
                    {String(label)}
                  </SelectOption>
                ))}
              </SelectList>
            </Select>
          </FormGroup>
        </GridItem>

        <GridItem md={4} lg={4} sm={4} ouiaId="scc-mirroring-policy-grid-item">
          <FormGroup
            label={
              <Tooltip
                content={__(
                  'The default mirroring policy for repositories which were created using this SCC Account.'
                )}
                ouiaId="scc-mirroring-policy-tooltip"
              >
                <span>{__('Mirroring Policy')}</span>
              </Tooltip>
            }
            fieldId="scc-mirroring-policy"
            ouiaId="scc-mirroring-policy-form-group"
          >
            <Select
              id="scc-mirroring-policy"
              isOpen={openMirroring}
              selected={mirroringPolicy}
              onSelect={(_, val) => {
                onMirroringPolicyChange(String(val));
                onMirroringOpenChange(false);
              }}
              onOpenChange={onMirroringOpenChange}
              ouiaId="scc-mirroring-policy-select"
              toggle={(ref) => (
                <MenuToggle
                  ref={ref}
                  isExpanded={openMirroring}
                  onClick={() => onMirroringOpenChange(!openMirroring)}
                  isFullWidth
                  ouiaId="scc-mirroring-policy-menu-toggle"
                >
                  {mirroringPolicy}
                </MenuToggle>
              )}
            >
              <SelectList ouiaId="scc-mirroring-policy-select-list">
                {mirroringPolicyOptions.map(([label], index) => (
                  <SelectOption
                    key={index}
                    value={String(label)}
                    ouiaId={`scc-mirroring-policy-option-${index}`}
                  >
                    {String(label)}
                  </SelectOption>
                ))}
              </SelectList>
            </Select>
          </FormGroup>
        </GridItem>
      </Grid>
    </CardBody>
  </Card>
);

SCCSyncSettingsCard.propTypes = {
  gpgKey: PropTypes.string.isRequired,
  gpgKeyOptions: PropTypes.arrayOf(
    PropTypes.arrayOf(
      PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.number,
        PropTypes.oneOf([null]),
      ])
    )
  ).isRequired,
  openGpg: PropTypes.bool.isRequired,
  downloadPolicy: PropTypes.string.isRequired,
  downloadPolicyOptions: PropTypes.arrayOf(
    PropTypes.oneOfType([
      PropTypes.exact({
        label: PropTypes.string.isRequired,
        value: PropTypes.string.isRequired,
      }),
      PropTypes.arrayOf(PropTypes.oneOfType([PropTypes.string])),
    ])
  ).isRequired,
  openDownload: PropTypes.bool.isRequired,
  mirroringPolicy: PropTypes.string.isRequired,
  mirroringPolicyOptions: PropTypes.arrayOf(
    PropTypes.oneOfType([
      PropTypes.exact({
        label: PropTypes.string.isRequired,
        value: PropTypes.string.isRequired,
      }),
      PropTypes.arrayOf(PropTypes.oneOfType([PropTypes.string])),
    ])
  ).isRequired,
  openMirroring: PropTypes.bool.isRequired,
  onGpgKeyChange: PropTypes.func.isRequired,
  onGpgOpenChange: PropTypes.func.isRequired,
  onDownloadPolicyChange: PropTypes.func.isRequired,
  onDownloadOpenChange: PropTypes.func.isRequired,
  onMirroringPolicyChange: PropTypes.func.isRequired,
  onMirroringOpenChange: PropTypes.func.isRequired,
};

export default SCCSyncSettingsCard;
