import componentRegistry from 'foremanReact/components/componentRegistry';
import injectReducer from 'foremanReact/redux/reducers/registerReducer';
import SCCProductPage from './components/SCCProductPage';
import reducer from './reducer';
import SCCAccountForm from './components/SCCAccountForm';

componentRegistry.register({
  name: 'SCCAccountForm',
  type: SCCAccountForm,
});

componentRegistry.register({
  name: 'SCCProductPage',
  type: SCCProductPage,
});

injectReducer('foremanSccManager', reducer);
