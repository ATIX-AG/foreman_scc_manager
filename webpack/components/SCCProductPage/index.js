import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as actions from './SCCProductPageActions';
import SCCProductPage from './SCCProductPage';
import * as Selector from './SCCProductPageSelectors';

// map state to props
const mapStateToProps = (state) => ({
  scc_products: Selector.selectSCCProducts(state),
  scc_account_id: Selector.selectSCCAccountId(state),
});

// map action dispatchers to props
const mapDispatchToProps = (dispatch) => bindActionCreators(actions, dispatch);

// export connected component
export default connect(mapStateToProps, mapDispatchToProps)(SCCProductPage);
