import React, { useState } from 'react';
import { Icon } from 'patternfly-react';
import PropTypes from 'prop-types';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import { foremanUrl } from 'foremanReact/common/helpers';
import {
  TreeView,
  Button,
  Card,
  CardTitle,
  CardBody,
  Tooltip,
  Flex,
  FlexItem,
} from '@patternfly/react-core';
import { BrowserRouter, Link } from 'react-router-dom';
import { cloneDeep, filter, clone } from 'lodash';
import SCCProductTreeExpander from '../common/SCCProductTreeExpander';
import SCCSubscribedProductsExpander from '../common/SCCSubscribedProductsExpander';
import SCCRepoView from './components/SCCRepoView';

const addCheckBoxToTree = (tree) => {
  const checkProps = {};
  checkProps.checked = tree.product_id !== null;
  checkProps.disabled = true;
  tree.checkProps = checkProps;
};

const addKatelloLinkToTree = (tree) => {
  const url = foremanUrl(`/products/${tree.product_id}`);
  // Link component needs to be wrapped in a Router
  tree.customBadgeContent.push(
    <BrowserRouter>
      <Link to={url} target="_blank">
        <Tooltip content={__('Go to Product page')}>
          <Button variant="plain" id="tt-ref">
            <Icon name="external-link" type="fa" />
          </Button>
        </Tooltip>
      </Link>
    </BrowserRouter>
  );
  return tree;
};

const addEditIcon = (tree, editProductTree) => {
  tree.customBadgeContent.push(
    <Tooltip content={__('Add more sub products to Product tree')}>
      <Button
        variant="plain"
        id={tree.id.toString()}
        onClick={(evt) => editProductTree(evt, tree.id)}
      >
        <Icon name="edit" type="pf" size="2x" />
      </Button>
    </Tooltip>
  );

  return tree;
};

const addReposToTree = (tree) => {
  tree.customBadgeContent.push(
    <Tooltip content={__('Show currently added repositories')}>
      <SCCRepoView
        sccRepos={tree.scc_repositories}
        sccProductId={tree.product_id}
      />
    </Tooltip>
  );
  return tree;
};

const addValidationStatusToTree = (tree) => {
  tree.customBadgeContent.push(
    <Tooltip content={__('Please check your SUSE subscription')}>
      <Button variant="plain">
        <Icon name="warning-triangle-o" type="pf" size="2x" />
      </Button>
    </Tooltip>
  );
  return tree;
};

const setupTreeViewListItem = (tree, isRoot, editProductTree) => {
  tree.key = 'view'.concat(tree.id.toString());
  tree.customBadgeContent = [];
  if (!tree.subscription_valid) addValidationStatusToTree(tree);
  addReposToTree(tree);
  addCheckBoxToTree(tree);
  if (tree.product_id !== null) {
    addKatelloLinkToTree(tree);
    if (isRoot) {
      addEditIcon(tree, editProductTree);
    }
  }
  if ('children' in tree) {
    tree.children = tree.children.map((c) =>
      setupTreeViewListItem(c, false, editProductTree)
    );
  }
  return tree;
};

const filterDeep = (tree) => {
  if (tree.product_id !== null) {
    const filtered = clone(tree);
    if ('children' in tree) {
      filtered.children = filter(
        tree.children,
        (child) => child.product_id !== null
      ).map(filterDeep);
      if (filtered.children.length === 0) {
        delete filtered.children;
      }
    }
    return filtered;
  }
  return null;
};

const SCCProductView = ({
  sccProducts,
  editProductTreeGlobal,
  subscriptionTaskId,
}) => {
  const editProductTree = (evt, productId) => {
    editProductTreeGlobal(productId);
  };
  const sccProductsClone = cloneDeep(sccProducts);
  // wrap actual iterator function into anonymous function to pass extra parameters
  const [allProducts, setAllProducts] = useState(
    sccProductsClone.map((tree) =>
      setupTreeViewListItem(tree, true, editProductTree)
    )
  );
  const [subscribedProducts, setSubscribedProducts] = useState(null);
  const [showAll, setShowAll] = useState(true);
  const [expandAll, setExpandAll] = useState();

  const showSubscribed = () => {
    if (subscribedProducts === null) {
      const test = allProducts.map(filterDeep);
      setSubscribedProducts(test);
    }
  };

  const setShowAllFromChild = (showAllFromChild) => {
    if (!showAllFromChild) {
      showSubscribed();
    }
    setShowAll(showAllFromChild);
  };

  const setExpandAllFromChild = (expandAllFromChild) => {
    setExpandAll(expandAllFromChild);
  };

  return (
    <Card>
      <CardTitle>{__('Selected SUSE Products')}</CardTitle>
      {sccProducts.length > 0 && (
        <CardBody>
          <Flex>
            <SCCProductTreeExpander
              setExpandAllInParent={setExpandAllFromChild}
            />
            <SCCSubscribedProductsExpander
              setExpandAllInParent={setShowAllFromChild}
            />
          </Flex>
          <Flex>
            <TreeView
              data={showAll ? allProducts : subscribedProducts}
              allExpanded={expandAll}
              hasChecks
              hasBadges
              hasGuides
            />
          </Flex>
        </CardBody>
      )}
      {sccProducts.length === 0 && (
        <CardBody>
          {__(
            'You currently have no SUSE products selected. Search and add SUSE products in the section below.'
          )}
        </CardBody>
      )}
      <Flex>
        {sccProducts.length > 0 && (
          <FlexItem>
            <Button variant="link">
              <BrowserRouter>
                <Link
                  to="/foreman_tasks/tasks/?search=Subscribe+SCC+Product"
                  target="_blank"
                >
                  {__('Show all subscription tasks')}
                </Link>
              </BrowserRouter>
            </Button>
          </FlexItem>
        )}
        {subscriptionTaskId !== '' && (
          <FlexItem>
            <Button variant="link">
              <BrowserRouter>
                <Link
                  to={sprintf('/foreman_tasks/tasks/%s', subscriptionTaskId)}
                  target="_blank"
                >
                  {__('Show last product subscription task')}
                </Link>
              </BrowserRouter>
            </Button>
          </FlexItem>
        )}
      </Flex>
    </Card>
  );
};

SCCProductView.propTypes = {
  sccProducts: PropTypes.array,
  editProductTreeGlobal: PropTypes.func,
  subscriptionTaskId: PropTypes.string,
};

SCCProductView.defaultProps = {
  sccProducts: undefined,
  editProductTreeGlobal: undefined,
  subscriptionTaskId: '',
};

export default SCCProductView;
