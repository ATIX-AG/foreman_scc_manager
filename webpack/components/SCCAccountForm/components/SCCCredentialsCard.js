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
  TextInput,
  Button,
  Tooltip,
  CardHeader,
} from '@patternfly/react-core';

const SCCCredentialsCard = ({
  name,
  login,
  password,
  baseUrl,
  testing,
  onNameChange,
  onLoginChange,
  onPasswordChange,
  onBaseUrlChange,
  onTestConnection,
}) => (
  <Card isFlat ouiaId="scc-credentials-card">
    <CardHeader ouiaId="scc-credentials-card-header">
      <CardTitle
        component="h2"
        className="pf-v5-u-font-size-xl pf-v5-u-mt-0"
        ouiaId="scc-credentials-card-title"
      >
        {__('SCC Account Credentials')}
      </CardTitle>
    </CardHeader>
    <CardBody ouiaId="scc-credentials-card-body">
      <Grid hasGutter ouiaId="scc-credentials-grid">
        <GridItem span={12} ouiaId="scc-name-grid-item">
          <FormGroup
            label={<span>{__('Name')}</span>}
            isRequired
            fieldId="scc-name"
            ouiaId="scc-name-form-group"
          >
            <TextInput
              id="scc-name"
              isRequired
              value={name}
              onChange={(_, val) => onNameChange(val)}
              ouiaId="scc-name-text-input"
            />
          </FormGroup>
        </GridItem>

        <GridItem span={12} ouiaId="scc-login-grid-item">
          <FormGroup
            label={
              <Tooltip
                content={__(
                  "Use your 'Organization credentials' obtained from the SUSE Customer Center."
                )}
                ouiaId="scc-login-tooltip"
              >
                <span>{__('Login')}</span>
              </Tooltip>
            }
            isRequired
            fieldId="scc-login"
            ouiaId="scc-login-form-group"
          >
            <TextInput
              id="scc-login"
              isRequired
              value={login}
              onChange={(_, val) => onLoginChange(val)}
              ouiaId="scc-login-text-input"
            />
          </FormGroup>
        </GridItem>

        <GridItem span={12} ouiaId="scc-password-grid-item">
          <FormGroup
            label={<span>{__('Password')}</span>}
            isRequired
            fieldId="scc-password"
            ouiaId="scc-password-form-group"
          >
            <TextInput
              id="scc-password"
              type="password"
              isRequired
              value={password}
              onChange={(_, val) => onPasswordChange(val)}
              ouiaId="scc-password-text-input"
            />
          </FormGroup>
        </GridItem>

        <GridItem span={12} ouiaId="scc-base-url-grid-item">
          <FormGroup
            label={<span>{__('Base URL')}</span>}
            isRequired
            fieldId="scc-base-url"
            ouiaId="scc-base-url-form-group"
          >
            <TextInput
              id="scc-base-url"
              value={baseUrl}
              onChange={(_, val) => onBaseUrlChange(val)}
              placeholder="https://scc.suse.com"
              ouiaId="scc-base-url-text-input"
            />
          </FormGroup>
        </GridItem>

        <GridItem span={12} ouiaId="scc-test-connection-grid-item">
          <div className="scc-account-form-test-connection">
            <Button
              variant="secondary"
              onClick={onTestConnection}
              isLoading={testing}
              isDisabled={testing}
              ouiaId="scc-test-connection-button"
            >
              {__('Test Connection')}
            </Button>
          </div>
        </GridItem>
      </Grid>
    </CardBody>
  </Card>
);

SCCCredentialsCard.propTypes = {
  name: PropTypes.string.isRequired,
  login: PropTypes.string.isRequired,
  password: PropTypes.string.isRequired,
  baseUrl: PropTypes.string.isRequired,
  testing: PropTypes.bool.isRequired,
  onNameChange: PropTypes.func.isRequired,
  onLoginChange: PropTypes.func.isRequired,
  onPasswordChange: PropTypes.func.isRequired,
  onBaseUrlChange: PropTypes.func.isRequired,
  onTestConnection: PropTypes.func.isRequired,
};

export default SCCCredentialsCard;
