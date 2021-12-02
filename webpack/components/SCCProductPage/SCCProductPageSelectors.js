const SCCProductPageSelector = (state) => state.foremanSccManager;

export const selectSCCProducts = (state) =>
  SCCProductPageSelector(state).sccProducts;

export const selectSCCAccountId = (state) =>
  SCCProductPageSelector(state).sccAccountId;
