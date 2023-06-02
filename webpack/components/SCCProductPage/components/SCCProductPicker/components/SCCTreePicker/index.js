import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import {
  TreeView,
  Button,
  Tooltip,
  Switch,
  Flex,
  FlexItem,
  Card,
  CardBody,
} from '@patternfly/react-core';
import { cloneDeep, merge, clone } from 'lodash';
import SCCRepoPicker from './components/SCCRepoPicker';
import { subscribeProductsWithReposAction } from '../../../../SCCProductPageActions';
import SCCProductTreeExpander from '../../../common/SCCProductTreeExpander';

const addCheckBoxToTree = (tree) => {
  const checkProps = {};
  checkProps.checked = tree.product_id !== null;
  checkProps.disabled = tree.product_id !== null;
  tree.checkProps = checkProps;

  return tree;
};

const addParentToTree = (tree, par) => {
  tree.parent = par;
  return tree;
};

const addSCCRepoPickerToTree = (
  tree,
  activateDebugFilter,
  setSelectedReposFromChild
) => {
  tree.customBadgeContent = [];
  tree.customBadgeContent.push(
    <Tooltip content={__('Filter repositories')}>
      <SCCRepoPicker
        sccRepos={tree.scc_repositories}
        disableRepos={tree.product_id === null && !tree.checkProps.checked}
        activateDebugFilter={activateDebugFilter}
        productAlreadySynced={tree.product_id !== null}
        sccProductId={tree.id}
        sccProductName={tree.name}
        setSelectedReposFromChild={setSelectedReposFromChild}
      />
    </Tooltip>
  );
  return tree;
};

const setupTreeViewListItem = (
  tree,
  isRoot,
  activateDebugFilter,
  setSelectedReposFromChild
) => {
  addCheckBoxToTree(tree);
  addSCCRepoPickerToTree(tree, activateDebugFilter, setSelectedReposFromChild);
  if ('children' in tree) {
    tree.children = tree.children.map((p) =>
      setupTreeViewListItem(
        p,
        false,
        activateDebugFilter,
        setSelectedReposFromChild
      )
    );
    tree.children.map((child) => addParentToTree(child, tree));
  }
  return tree;
};

const checkAllParents = (
  tree,
  activateDebugFilter,
  setSelectedReposFromChild
) => {
  if (!tree.checkProps.checked) {
    tree.checkProps.checked = true;
    addSCCRepoPickerToTree(
      tree,
      activateDebugFilter,
      setSelectedReposFromChild
    );
  }
  if (tree.parent)
    checkAllParents(
      tree.parent,
      activateDebugFilter,
      setSelectedReposFromChild
    );

  return tree;
};

const uncheckAllChildren = (
  tree,
  activateDebugFilter,
  setSelectedReposFromChild
) => {
  if (tree.product_id === null) {
    tree.checkProps.checked = false;
    addSCCRepoPickerToTree(
      tree,
      activateDebugFilter,
      setSelectedReposFromChild
    );
  }
  if ('children' in tree)
    tree.children = tree.children.map((c) =>
      uncheckAllChildren(c, activateDebugFilter, setSelectedReposFromChild)
    );

  return tree;
};

const getRootParent = (tree) => {
  if (tree.parent) return getRootParent(tree.parent);

  return tree;
};

const SCCTreePicker = ({
  sccProducts,
  sccAccountId,
  resetFormFromParent,
  handleSubscribeCallback,
}) => {
  const dispatch = useDispatch();
  // this needs to be uninitialized such that the first call to setAllExpanded can actually
  // change the value of allExpanded
  const [expandAll, setExpandAll] = useState();
  const [selectedRepos, setSelectedRepos] = useState({});
  // the debug filter is actually a 'includeDebugRepos' setting which should not be active by default
  const [activateDebugFilter, setActivateDebugFilter] = useState(false);

  const setSelectedReposFromChild = (
    productId,
    productName,
    repoIds,
    repoNames
  ) => {
    if (repoIds.length !== 0) {
      selectedRepos[productId] = {};
      selectedRepos[productId].repoIds = repoIds;
      selectedRepos[productId].productName = productName;
      selectedRepos[productId].repoNames = repoNames;
      const newSelectedRepos = clone(selectedRepos);
      setSelectedRepos(newSelectedRepos);
    } else if (selectedRepos !== {} && productId in selectedRepos) {
      delete selectedRepos[productId];
      const newSelectedRepos = clone(selectedRepos);
      setSelectedRepos(newSelectedRepos);
    }
  };

  const [sccProductTree, setSccProductTree] = useState(
    cloneDeep(sccProducts).map((p) =>
      setupTreeViewListItem(
        p,
        true,
        activateDebugFilter,
        setSelectedReposFromChild
      )
    )
  );

  useEffect(() => {
    setSccProductTree(
      cloneDeep(sccProducts).map((p) =>
        setupTreeViewListItem(
          p,
          true,
          activateDebugFilter,
          setSelectedReposFromChild
        )
      )
    );
    // some thorough cleaning is required for hash maps
    Object.keys(selectedRepos).forEach((k) => delete selectedRepos[k]);
  }, [sccProducts]);

  const setExpandAllFromChild = (expandAllFromChild) => {
    setExpandAll(expandAllFromChild);
  };

  const debugFilterChange = (evt) => {
    setActivateDebugFilter(!activateDebugFilter);
  };

  const onCheck = (evt, treeViewItem) => {
    if (evt.target.checked) {
      checkAllParents(
        treeViewItem,
        activateDebugFilter,
        setSelectedReposFromChild
      );
    } else {
      uncheckAllChildren(
        treeViewItem,
        activateDebugFilter,
        setSelectedReposFromChild
      );
    }

    setSccProductTree([...merge(sccProductTree, getRootParent(treeViewItem))]);
  };

  const submitForm = (evt) => {
    const productsToSubscribe = [];
    Object.keys(selectedRepos).forEach((k) => {
      const repo = {
        scc_product_id: parseInt(k, 10),
        repository_list: selectedRepos[k].repoIds,
      };
      productsToSubscribe.push(repo);
    });
    dispatch(
      subscribeProductsWithReposAction(
        sccAccountId,
        productsToSubscribe,
        handleSubscribeCallback,
        selectedRepos
      )
    );
    // reset data structure and form
    setSelectedRepos({});
    resetFormFromParent();
  };

  return (
    <Card>
      <CardBody>
        <Flex direction={{ default: 'column' }}>
          <Flex>
            <SCCProductTreeExpander
              setExpandAllInParent={setExpandAllFromChild}
            />
            <FlexItem>
              <Tooltip
                content={__(
                  'If this option is enabled, debug and source pool repositories are automatically selected if you select a product. This option is disabled by default. It applies for unselected products, only. Already selected products are not filtered.'
                )}
              >
                <Switch
                  id="filter-debug-switch"
                  onChange={debugFilterChange}
                  isChecked={activateDebugFilter}
                  label={__('Include Debug and Source Pool repositories')}
                />
              </Tooltip>
            </FlexItem>
          </Flex>
          <Flex>
            <TreeView
              data={sccProductTree}
              allExpanded={expandAll}
              onCheck={onCheck}
              hasChecks
              hasBadges
              hasGuides
            />
          </Flex>
          <Flex>
            <Button
              variant="primary"
              onClick={submitForm}
              isDisabled={Object.keys(selectedRepos).length === 0}
            >
              {__('Add product(s)')}
            </Button>
          </Flex>
        </Flex>
      </CardBody>
    </Card>
  );
};

SCCTreePicker.propTypes = {
  sccProducts: PropTypes.array,
  sccAccountId: PropTypes.number.isRequired,
  resetFormFromParent: PropTypes.func.isRequired,
  handleSubscribeCallback: PropTypes.func.isRequired,
};

SCCTreePicker.defaultProps = {
  sccProducts: [],
};

export default SCCTreePicker;
