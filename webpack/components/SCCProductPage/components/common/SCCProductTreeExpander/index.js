import React from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import SCCGenericExpander from '../SCCGenericExpander';

const SCCProductTreeExpander = ({ setExpandAllInParent, ouiaId }) => (
  <SCCGenericExpander
    setInParent={setExpandAllInParent}
    selectOptionOpen={__('Expand products')}
    selectOptionClose={__('Collapse products')}
    initLabel={__('Collapse/Expand')}
    ouiaId={ouiaId}
  />
);

SCCProductTreeExpander.propTypes = {
  setExpandAllInParent: PropTypes.func.isRequired,
  ouiaId: PropTypes.string.isRequired,
};

SCCProductTreeExpander.defaultProps = {};

export default SCCProductTreeExpander;
