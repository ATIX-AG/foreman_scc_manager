import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { translate as __ } from 'foremanReact/common/I18n';
import { foremanUrl } from 'foremanReact/common/helpers';
import PropTypes from 'prop-types';
import {
  PageSection,
  Title,
  Form,
  Button,
  Stack,
  StackItem,
} from '@patternfly/react-core';

import { formatDateTime } from './components/DateTimeField';
import SCCCredentialsCard from './components/SCCCredentialsCard';
import SCCTokenRefreshCard from './components/SCCTokenRefreshCard';
import SCCSyncSettingsCard from './components/SCCSyncSettingsCard';
import {
  testSccConnectionAction,
  submitSccAccountAction,
} from './SCCAccountFormActions';
import './SCCAccountForm.scss';

const SCCAccountForm = ({
  organizationId,
  intervalOptions,
  downloadPolicyOptions,
  mirroringPolicyOptions,
  gpgKeyOptions,
  selectedGpgKeyId,
  initial,
}) => {
  const isEdit = Boolean(initial?.id);
  const dispatch = useDispatch();

  const [openInterval, setOpenInterval] = useState(false);
  const [openGpg, setOpenGpg] = useState(false);
  const [openDownload, setOpenDownload] = useState(false);
  const [openMirroring, setOpenMirroring] = useState(false);

  const [name, setName] = useState(initial?.name ?? '');
  const [login, setLogin] = useState(initial?.login ?? '');
  const [password, setPassword] = useState(isEdit ? '********' : '');

  const [baseUrl, setBaseUrl] = useState(
    initial?.baseUrl ?? 'https://scc.suse.com'
  );

  const [refreshDate, setRefreshDate] = useState(initial?.refreshDate ?? '');
  const [refreshTime, setRefreshTime] = useState(initial?.refreshTime ?? '');

  const [testing, setTesting] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const [interval, setInterval] = useState(
    initial?.interval ?? intervalOptions?.[0] ?? ''
  );

  const [gpgKey, setGpgKey] = useState(
    initial?.gpgKey ?? selectedGpgKeyId ?? gpgKeyOptions?.[0]?.[0] ?? ''
  );

  const [downloadPolicy, setDownloadPolicy] = useState(
    initial?.downloadPolicy ?? downloadPolicyOptions?.[0]?.[0] ?? ''
  );

  const [mirroringPolicy, setMirroringPolicy] = useState(
    initial?.mirroringPolicy ?? mirroringPolicyOptions?.[0]?.[0] ?? ''
  );

  const handleUrl = (url) => {
    if (!url) return;
    try {
      const parsed = new URL(url);
      if (parsed.protocol === 'http:' || parsed.protocol === 'https:') {
        setBaseUrl(url);
        return;
      }
    } catch {
      // ignore parse errors
    }
    setBaseUrl(url);
  };

  const buildPayload = () => {
    const downloadPolicyValue =
      downloadPolicyOptions.find(([label]) => label === downloadPolicy)?.[1] ??
      downloadPolicy;

    const mirroringPolicyValue =
      mirroringPolicyOptions.find(
        ([label]) => label === mirroringPolicy
      )?.[1] ?? mirroringPolicy;

    const katelloGpgKeyId = !gpgKey
      ? null
      : gpgKeyOptions.find(([label]) => label === gpgKey)?.[1] ?? null;

    const payload = {
      name,
      login,
      password: isEdit && password === '********' ? null : password,
      base_url: baseUrl,
      interval,
      download_policy: downloadPolicyValue,
      mirroring_policy: mirroringPolicyValue,
      organization_id: organizationId,
      katello_gpg_key_id: katelloGpgKeyId,
    };
    const sync = formatDateTime(refreshDate, refreshTime);
    if (sync) payload.sync_date = sync;

    return payload;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (submitting) return;

    setSubmitting(true);
    const payload = buildPayload();

    const action = submitSccAccountAction({
      isEdit,
      organizationId,
      updateUrl: `/api/v2/scc_accounts/${initial?.id}`,
      payload,
      onSuccess: (redirect) => {
        setSubmitting(false);
        window.location.href = redirect;
      },
      onError: () => setSubmitting(false),
    });

    dispatch(action);
  };
  const handleTestConnection = () => {
    setTesting(true);

    const action = testSccConnectionAction({
      login: isEdit && login === initial?.login ? '' : login,
      password: isEdit && password === '********' ? '' : password,
      baseUrl: isEdit && baseUrl === initial?.baseUrl ? '' : baseUrl,
      isEdit,
      id: initial?.id,
      onFinally: () => setTesting(false),
    });

    const dispatchedAction = dispatch(action);
    if (dispatchedAction?.finally)
      dispatchedAction.finally(() => setTesting(false));
  };

  return (
    <PageSection
      isFilled
      className="scc-account-form-section"
      ouiaId="scc-account-form-page-section"
    >
      <Title
        headingLevel="h1"
        className="scc-account-form-title"
        ouiaId="scc-account-form-title"
      >
        SUSE Customer Center Account
      </Title>

      <Form
        isWidthLimited
        className="scc-account-form"
        onSubmit={handleSubmit}
        ouiaId="scc-account-form"
      >
        <Stack hasGutter ouiaId="scc-account-form-stack">
          <StackItem ouiaId="scc-credentials-stack-item">
            <SCCCredentialsCard
              name={name}
              login={login}
              password={password}
              baseUrl={baseUrl}
              testing={testing}
              onNameChange={setName}
              onLoginChange={setLogin}
              onPasswordChange={setPassword}
              onBaseUrlChange={handleUrl}
              onTestConnection={handleTestConnection}
            />
          </StackItem>

          <StackItem ouiaId="scc-token-refresh-stack-item">
            <SCCTokenRefreshCard
              interval={interval}
              intervalOptions={intervalOptions}
              openInterval={openInterval}
              refreshDate={refreshDate}
              refreshTime={refreshTime}
              onIntervalChange={setInterval}
              onIntervalOpenChange={setOpenInterval}
              onRefreshDateChange={setRefreshDate}
              onRefreshTimeChange={setRefreshTime}
            />
          </StackItem>

          <StackItem ouiaId="scc-sync-settings-stack-item">
            <SCCSyncSettingsCard
              gpgKey={gpgKey}
              gpgKeyOptions={gpgKeyOptions}
              openGpg={openGpg}
              downloadPolicy={downloadPolicy}
              downloadPolicyOptions={downloadPolicyOptions}
              openDownload={openDownload}
              mirroringPolicy={mirroringPolicy}
              mirroringPolicyOptions={mirroringPolicyOptions}
              openMirroring={openMirroring}
              onGpgKeyChange={setGpgKey}
              onGpgOpenChange={setOpenGpg}
              onDownloadPolicyChange={setDownloadPolicy}
              onDownloadOpenChange={setOpenDownload}
              onMirroringPolicyChange={setMirroringPolicy}
              onMirroringOpenChange={setOpenMirroring}
            />
          </StackItem>

          <StackItem ouiaId="scc-form-actions-stack-item">
            <Button
              variant="primary"
              type="submit"
              isDisabled={submitting}
              ouiaId="scc-form-submit-button"
            >
              {__('Submit')}
            </Button>{' '}
            <Button
              variant="link"
              component="a"
              href={foremanUrl('/scc_accounts')}
              isDisabled={submitting}
              ouiaId="scc-form-cancel-button"
            >
              {__('Cancel')}
            </Button>
          </StackItem>
        </Stack>
      </Form>
    </PageSection>
  );
};

SCCAccountForm.propTypes = {
  organizationId: PropTypes.number.isRequired,
  intervalOptions: PropTypes.arrayOf(PropTypes.string),
  downloadPolicyOptions: PropTypes.arrayOf(
    PropTypes.oneOfType([
      PropTypes.exact({
        label: PropTypes.string.isRequired,
        value: PropTypes.string.isRequired,
      }),
      PropTypes.arrayOf(PropTypes.oneOfType([PropTypes.string])),
    ])
  ),
  mirroringPolicyOptions: PropTypes.arrayOf(
    PropTypes.oneOfType([
      PropTypes.exact({
        label: PropTypes.string.isRequired,
        value: PropTypes.string.isRequired,
      }),
      PropTypes.arrayOf(PropTypes.oneOfType([PropTypes.string])),
    ])
  ),
  gpgKeyOptions: PropTypes.arrayOf(
    PropTypes.arrayOf(
      PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.number,
        PropTypes.oneOf([null]),
      ])
    )
  ),
  selectedGpgKeyId: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.oneOf(['', null]),
  ]),
  initial: PropTypes.shape({
    id: PropTypes.number,
    name: PropTypes.string,
    login: PropTypes.string,
    baseUrl: PropTypes.string,
    interval: PropTypes.string,
    downloadPolicy: PropTypes.string,
    mirroringPolicy: PropTypes.string,
    gpgKey: PropTypes.oneOfType([PropTypes.number, PropTypes.oneOf(['None'])]),
    refreshDate: PropTypes.string,
    refreshTime: PropTypes.string,
  }),
};

SCCAccountForm.defaultProps = {
  intervalOptions: [],
  downloadPolicyOptions: [],
  mirroringPolicyOptions: [],
  gpgKeyOptions: [],
  selectedGpgKeyId: '',
  initial: {},
};
export default SCCAccountForm;
