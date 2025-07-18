import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { TimesIcon } from '@patternfly/react-icons';
import {
  Button,
  Card,
  CardTitle,
  CardBody,
  CardHeader,
  CardExpandableContent,
  Flex,
  FlexItem,
} from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import { uniq } from 'lodash';
import './styles.scss';
import SCCGenericPicker from './components/SCCGenericPicker';
import SCCTreePicker from './components/SCCTreePicker';

const resetSelectionStringProduct = __(' -- Select Product --');
const resetSelectionStringVersion = __(' -- Select Version --');
const resetSelectionStringArch = __(' -- Select Architecture --');

const genericFilter = (object, comparator) =>
  // we can have architectures that are not set
  comparator === '' ||
  object === comparator ||
  (object === null && comparator === 'no arch');

const filterVersionByProduct = (sccProducts, product) =>
  uniq(
    sccProducts
      .filter((p) => p.product_category === product)
      .map((i) => i.version)
  ).sort();

const filterArchByVersionAndProduct = (sccProducts, product, version) =>
  uniq(
    sccProducts
      .filter((p) => p.product_category === product && p.version === version)
      .map((i) => i.arch)
  ).sort();

const SCCProductPicker = ({
  sccProducts,
  sccAccountId,
  editProductId,
  handleSubscribeCallback,
}) => {
  const [productItems] = useState(
    uniq(sccProducts.map((p) => p.product_category))
  );
  const [selectedProduct, setSelectedProduct] = useState('');
  const [archItems, setArchItems] = useState([]);
  const [selectedArch, setSelectedArch] = useState('');
  const [versionItems, setVersionItems] = useState([]);
  const [selectedVersion, setSelectedVersion] = useState('');
  const [filteredSccProducts, setFilteredSccProducts] = useState([]);
  const [showSearchTree, setShowSearchTree] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [searchInputProduct, setSearchInputProduct] = useState('');
  const [searchInputVersion, setSearchInputVersion] = useState('');
  const [searchInputArch, setSearchInputArch] = useState('');

  useEffect(() => {
    if (editProductId !== 0) {
      // the id is unique, so there never should be more than 1 element in the array
      const product = sccProducts.filter((p) => p.id === editProductId);
      if (product.length > 0) {
        setSelectedProduct(product[0].product_category);
        setSelectedArch(product[0].arch);
        setSelectedVersion(product[0].version);
        setFilteredSccProducts(product);
        setShowSearchTree(true);
        setIsExpanded(true);
      }
    }
  }, [editProductId, sccProducts]);

  const onProductSelectionChange = (value) => {
    if (value === '') {
      setVersionItems([]);
      setSearchInputVersion('');
      setSearchInputArch('');
    } else {
      setVersionItems(filterVersionByProduct(sccProducts, value));
    }
    setSelectedProduct(value);
    setArchItems([]);
    setSelectedVersion('');
    setSelectedArch('');
  };

  const onVersionSelectionChange = (value) => {
    if (value === '') {
      setArchItems([]);
      setSearchInputArch('');
    } else {
      setArchItems(
        filterArchByVersionAndProduct(sccProducts, selectedProduct, value)
      );
    }
    setSelectedVersion(value);
    setSelectedArch('');
  };

  const onArchSelectionChange = (value) => {
    if (value === '') {
      setArchItems([]);
    }
    setSelectedArch(value);
  };

  const onExpand = (evt, id) => {
    setIsExpanded(!isExpanded);
  };

  const filterProducts = (evt) => {
    setShowSearchTree(true);
    setFilteredSccProducts(
      sccProducts.filter(
        (p) =>
          genericFilter(p.product_category, selectedProduct) &&
          genericFilter(p.arch, selectedArch) &&
          genericFilter(p.version, selectedVersion)
      )
    );
  };

  const resetTreeForm = () => {
    setShowSearchTree(false);
    setSelectedProduct('');
    setSelectedVersion('');
    setSelectedArch('');
    setVersionItems([]);
    setArchItems([]);
    setSearchInputProduct('');
    setSearchInputVersion('');
    setSearchInputArch('');
  };

  return (
    <Card
      border="dark"
      ouiaId="scc-manager-product-selection-card"
      id="product-selection-card"
      isExpanded={isExpanded}
    >
      <CardHeader onExpand={onExpand}>
        <CardTitle>{__('Select SUSE products')}</CardTitle>
      </CardHeader>
      <CardExpandableContent>
        <CardBody>
          <Flex direction={{ default: 'column' }}>
            <Flex>
              <FlexItem>
                <SCCGenericPicker
                  key="scc-prod-select"
                  initialSelectOptions={productItems}
                  setSelected={onProductSelectionChange}
                  initialLabel={
                    selectedProduct === ''
                      ? resetSelectionStringProduct
                      : selectedProduct
                  }
                  selected={selectedProduct}
                  inputValue={searchInputProduct}
                  setInputValue={setSearchInputProduct}
                />
              </FlexItem>
              <FlexItem>
                <SCCGenericPicker
                  key="scc-vers-select"
                  initialSelectOptions={versionItems}
                  setSelected={onVersionSelectionChange}
                  initialLabel={
                    selectedVersion === ''
                      ? resetSelectionStringVersion
                      : selectedVersion
                  }
                  selected={selectedVersion}
                  inputValue={searchInputVersion}
                  setInputValue={setSearchInputVersion}
                />
              </FlexItem>
              <FlexItem>
                <SCCGenericPicker
                  key="scc-arch-select"
                  initialSelectOptions={archItems}
                  setSelected={onArchSelectionChange}
                  initialLabel={
                    selectedArch === ''
                      ? resetSelectionStringArch
                      : selectedArch
                  }
                  selected={selectedArch}
                  inputValue={searchInputArch}
                  setInputValue={setSearchInputArch}
                />
              </FlexItem>
              <FlexItem>
                <Button
                  ouiaId="scc-manager-product-search-button"
                  variant="primary"
                  onClick={filterProducts}
                >
                  {__('Search')}
                </Button>
              </FlexItem>
              <FlexItem>
                <Button
                  ouiaId="scc-manager-product-search-reset-button"
                  variant="link"
                  icon={<TimesIcon />}
                  onClick={resetTreeForm}
                >
                  {__('Reset Selection')}
                </Button>
              </FlexItem>
            </Flex>
            <FlexItem>
              {showSearchTree && (
                <SCCTreePicker
                  sccProducts={filteredSccProducts}
                  sccAccountId={sccAccountId}
                  resetFormFromParent={resetTreeForm}
                  handleSubscribeCallback={handleSubscribeCallback}
                />
              )}
            </FlexItem>
          </Flex>
        </CardBody>
      </CardExpandableContent>
    </Card>
  );
};

SCCProductPicker.propTypes = {
  sccProducts: PropTypes.array,
  sccAccountId: PropTypes.number.isRequired,
  editProductId: PropTypes.number,
  handleSubscribeCallback: PropTypes.func.isRequired,
};

SCCProductPicker.defaultProps = {
  sccProducts: [],
  editProductId: 0,
};

export default SCCProductPicker;
