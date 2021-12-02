import componentRegistry from 'foremanReact/components/componentRegistry';
import injectReducer from 'foremanReact/redux/reducers/registerReducer';
import SCCProductPage from './components/SCCProductPage';
import reducer from './reducer';

componentRegistry.register({
  name: 'SCCProductPage',
  type: SCCProductPage,
});

injectReducer('foremanSccManager', reducer);
