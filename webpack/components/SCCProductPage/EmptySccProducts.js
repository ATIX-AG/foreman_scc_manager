import React from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { Button } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import EmptyState from 'foremanReact/components/common/EmptyState';
import { syncSccAccountAction } from './SCCProductPageActions';

export const EmptySccProducts = ({ canCreate, sccAccountId }) => {
  const dispatch = useDispatch();
  const onSyncStart = (evt) => {
    dispatch(syncSccAccountAction(sccAccountId));
  };

  const content = __(
    `Please synchronize your SUSE account before you can subscribe to SUSE products.`
  );
  return (
    <>
      <EmptyState
        icon="th"
        iconType="fa"
        header={__('SUSE Customer Center')}
        description={<div dangerouslySetInnerHTML={{ __html: content }} />}
        documentation={{
          url: 'https://docs.orcharhino.com/or/docs/sources/usage_guides/managing_sles_systems_guide.html#mssg_adding_scc_accounts',
        }}
      />
      <Button
        onClick={onSyncStart}
        ouiaId="scc-manager-welcome-sync-products"
        className="btn btn-primary"
      >
        {__('Synchronize SUSE Account')}
      </Button>
    </>
  );
};

EmptySccProducts.propTypes = {
  canCreate: PropTypes.bool,
  sccAccountId: PropTypes.number,
};

EmptySccProducts.defaultProps = {
  canCreate: false,
  sccAccountId: undefined,
};

export default EmptySccProducts;
