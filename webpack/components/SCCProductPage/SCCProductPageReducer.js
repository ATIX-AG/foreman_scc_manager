import Immutable from 'seamless-immutable';
import { actionTypeGenerator } from 'foremanReact/redux/API';

export const initialState = Immutable({
  sccProducts: [],
  sccAccountId: undefined,
});

export default (state = initialState, action) => {
  const { payload } = action;

  const listTypes = actionTypeGenerator('SCC_PRODUCT_LIST');

  switch (action.type) {
    case 'FETCH_PRODUCT_SUCCESS':
      return state.merge({
        sccProducts: payload,
      });
    case listTypes.REQUEST:
      return state.merge({
        sccProducts: [],
      });
    case listTypes.SUCCESS:
      return state.merge({
        sccProducts: payload.data,
      });
    case listTypes.FAILURE:
      return state.merge({
        sccProducts: [payload.error],
      });
    default:
      return state;
  }
};
