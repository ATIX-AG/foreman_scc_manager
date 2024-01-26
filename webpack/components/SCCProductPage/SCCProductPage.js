import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { Stack, StackItem } from '@patternfly/react-core';
import { useDispatch } from 'react-redux';
import { translate as __ } from 'foremanReact/common/I18n';
import { useForemanModal } from 'foremanReact/components/ForemanModal/ForemanModalHooks';
import SCCProductView from './components/SCCProductView';
import { EmptySccProducts } from './EmptySccProducts';
import SCCProductPicker from './components/SCCProductPicker';
import SCCProductPickerModal from './components/SCCProductPickerModal';
import { SCCPRODUCTPAGE_SUMMARY_MODAL_ID } from './SCCProductPageConstants';
import './sccProductPage.scss';

const SCCProductPage = ({
  canCreate,
  sccAccountId,
  sccProductsInit,
  ...props
}) => {
  const dispatch = useDispatch();
  const [productToEdit, setProductToEdit] = useState(0);
  const [reposToSubscribe, setReposToSubscribe] = useState([]);
  const [subscriptionTaskId, setSubscriptionTaskId] = useState();

  const editProductTree = (productId) => {
    setProductToEdit(productId);
  };

  const { setModalOpen } = useForemanModal({
    id: SCCPRODUCTPAGE_SUMMARY_MODAL_ID,
  });

  const handleSubscribeCallback = (
    subscriptionTaskIdFromAction,
    reposToSubscribeFromAction
  ) => {
    setSubscriptionTaskId(subscriptionTaskIdFromAction);
    const newReposToSubscribe = [];
    Object.keys(reposToSubscribeFromAction).forEach((k) => {
      const repo = {
        productName: reposToSubscribeFromAction[k].productName,
        repoNames: reposToSubscribeFromAction[k].repoNames,
      };
      newReposToSubscribe.push(repo);
    });
    setReposToSubscribe(newReposToSubscribe);
    dispatch(setModalOpen({ id: SCCPRODUCTPAGE_SUMMARY_MODAL_ID }));
  };

  return sccProductsInit.length > 0 ? (
    <Stack>
      <StackItem>
        <SCCProductPickerModal
          id={SCCPRODUCTPAGE_SUMMARY_MODAL_ID}
          title={__('The subscription task has been started successfully')}
          taskId={subscriptionTaskId}
          reposToSubscribe={reposToSubscribe}
        />
      </StackItem>
      <StackItem>
        <SCCProductView
          sccProducts={sccProductsInit.filter(
            (prod) => prod.product_id !== null
          )}
          subscriptionTaskId={subscriptionTaskId}
          editProductTreeGlobal={editProductTree}
        />
      </StackItem>
      <br />
      <StackItem />
      <StackItem>
        <SCCProductPicker
          sccProducts={sccProductsInit}
          sccAccountId={sccAccountId}
          editProductId={productToEdit}
          handleSubscribeCallback={handleSubscribeCallback}
        />
      </StackItem>
    </Stack>
  ) : (
    <EmptySccProducts sccAccountId={sccAccountId} canCreate={canCreate} />
  );
};

SCCProductPage.propTypes = {
  canCreate: PropTypes.bool,
  sccAccountId: PropTypes.number.isRequired,
  sccProductsInit: PropTypes.array,
};

SCCProductPage.defaultProps = {
  canCreate: false,
  sccProductsInit: [],
};

export default SCCProductPage;
