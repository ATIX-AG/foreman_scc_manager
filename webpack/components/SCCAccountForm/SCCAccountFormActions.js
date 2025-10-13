import { post, put } from 'foremanReact/redux/API';
import { translate as __ } from 'foremanReact/common/I18n';

export const testSccConnectionAction = ({
  login,
  password,
  baseUrl,
  onFinally,
  isEdit,
  id,
}) => {
  const params = { scc_account: { login, password, base_url: baseUrl } };
  const request = isEdit ? put : post;

  const handleFinally = () => {
    if (onFinally) onFinally();
  };

  return request({
    key: isEdit ? `testSccConnection_${id}` : 'testSccConnection',
    url: isEdit
      ? `/api/v2/scc_accounts/${id}/test_connection`
      : '/api/v2/scc_accounts/test_connection',
    params,
    successToast: () => __('Connection OK'),
    errorToast: () => __('Connection test failed.'),
    handleSuccess: handleFinally,
    handleError: handleFinally,
  });
};

export const submitSccAccountAction = ({
  isEdit,
  organizationId,
  updateUrl,
  payload,
  onSuccess,
  onError,
}) => {
  const params = { scc_account: payload };
  const request = isEdit ? put : post;
  const url = isEdit ? updateUrl : '/api/v2/scc_accounts';

  const handleSuccess = (response) => {
    const redirect =
      response?.data?.redirect ||
      response?.data?.location ||
      response?.redirect;

    if (onSuccess) onSuccess(redirect || '/scc_accounts');
  };

  const handleError = () => {
    if (onError) onError();
  };

  return request({
    key: isEdit
      ? `updateSccAccount_${organizationId}`
      : `createSccAccount_${organizationId}`,
    url,
    params,
    successToast: () =>
      isEdit
        ? __('SCC account updated successfully.')
        : __('SCC account created successfully.'),
    errorToast: () =>
      isEdit
        ? __('Failed to update SCC account.')
        : __('Failed to create SCC account.'),
    handleSuccess,
    handleError,
  });
};
