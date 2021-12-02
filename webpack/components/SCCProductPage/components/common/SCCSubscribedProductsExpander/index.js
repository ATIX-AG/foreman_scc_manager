import React from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import SCCGenericExpander from '../SCCGenericExpander';

const SCCSubscribedProductsExpander = ({ setExpandAllInParent }) => (
  <SCCGenericExpander
    setInParent={setExpandAllInParent}
    selectOptionOpen={__('Show all products')}
    selectOptionClose={__('Show only subscribed products')}
    initLabel={__('Show/Hide unsubscribed')}
  />
);

SCCSubscribedProductsExpander.propTypes = {
  setExpandAllInParent: PropTypes.func.isRequired,
};

SCCSubscribedProductsExpander.defaultProps = {};

export default SCCSubscribedProductsExpander;
