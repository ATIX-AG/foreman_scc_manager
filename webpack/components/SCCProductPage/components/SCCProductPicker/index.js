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
  comparator === resetSelectionStringProduct ||
  comparator === resetSelectionStringVersion ||
  comparator === resetSelectionStringArch ||
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
    if (value !== resetSelectionStringProduct) {
      setVersionItems(filterVersionByProduct(sccProducts, value));
    } else {
      setVersionItems([]);
    }
    setSelectedProduct(value);
    setArchItems([]);
    setSelectedVersion('');
    setSelectedArch('');
  };

  const onVersionSelectionChange = (value) => {
    if (value === resetSelectionStringVersion) {
      setArchItems([]);
    } else {
      setArchItems(
        filterArchByVersionAndProduct(sccProducts, selectedProduct, value)
      );
    }
    setSelectedVersion(value);
    setSelectedArch('');
  };

  const onArchSelectionChange = (value) => {
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
  };

  return (
    <Card border="dark" id="product-selection-card" isExpanded={isExpanded}>
      <CardHeader onExpand={onExpand}>
        <CardTitle>{__('Select SUSE products')}</CardTitle>
      </CardHeader>
      <CardExpandableContent>
        <CardBody>
          <Flex direction={{ default: 'column' }}>
            <Flex>
              <FlexItem>
                <SCCGenericPicker
                  key="prod-select"
                  selectionItems={
                    selectedProduct === ''
                      ? productItems
                      : [resetSelectionStringProduct].concat(productItems)
                  }
                  setGlobalSelected={onProductSelectionChange}
                  screenReaderLabel={resetSelectionStringProduct}
                  initialLabel={
                    selectedProduct === ''
                      ? resetSelectionStringProduct
                      : selectedProduct
                  }
                />
              </FlexItem>
              <FlexItem>
                <SCCGenericPicker
                  key="vers-select"
                  selectionItems={
                    selectedVersion === ''
                      ? versionItems
                      : [resetSelectionStringVersion].concat(versionItems)
                  }
                  setGlobalSelected={onVersionSelectionChange}
                  screenReaderLabel={resetSelectionStringVersion}
                  initialLabel={
                    selectedVersion === ''
                      ? resetSelectionStringVersion
                      : selectedVersion
                  }
                />
              </FlexItem>
              <FlexItem>
                <SCCGenericPicker
                  key="arch-select"
                  selectionItems={
                    selectedArch === ''
                      ? archItems
                      : [resetSelectionStringArch].concat(archItems)
                  }
                  setGlobalSelected={onArchSelectionChange}
                  screenReaderLabel={resetSelectionStringArch}
                  initialLabel={
                    selectedArch === ''
                      ? resetSelectionStringArch
                      : selectedArch
                  }
                />
              </FlexItem>
              <FlexItem>
                <Button variant="primary" onClick={filterProducts}>
                  {__('Search')}
                </Button>
              </FlexItem>
              <FlexItem>
                <Button
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
