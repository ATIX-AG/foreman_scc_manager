import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { ContextSelector, ContextSelectorItem } from '@patternfly/react-core';

const GenericSelector = ({
  selectionItems,
  setGlobalSelected,
  screenReaderLabel,
  initialLabel,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [selected, setSelected] = useState(initialLabel);
  const [searchValue, setSearchValue] = useState('');
  const [filteredItems, setFilteredItems] = useState(selectionItems);

  useEffect(() => {
    setFilteredItems(selectionItems);
    setSelected(initialLabel);
  }, [selectionItems, initialLabel]);

  const onToggle = (selectorOpen) => {
    setIsOpen(selectorOpen);
  };

  const onSelect = (event, value) => {
    setSelected(value);
    setIsOpen(!isOpen);
    setGlobalSelected(value);
  };

  const onSearchInputChange = (value) => {
    setSearchValue(value);
  };

  const onSearchButtonClick = (event) => {
    const filtered =
      searchValue === ''
        ? selectionItems
        : selectionItems.filter((item) => {
            const str = item.text ? item.text : item;
            return str.toLowerCase().indexOf(searchValue.toLowerCase()) !== -1;
          });

    setFilteredItems(filtered || []);
  };

  return (
    <ContextSelector
      toggleText={selected}
      onSearchInputChange={onSearchInputChange}
      isOpen={isOpen}
      searchInputValue={searchValue}
      onToggle={onToggle}
      onSelect={onSelect}
      onSearchButtonClick={onSearchButtonClick}
      screenReaderLabel={screenReaderLabel}
    >
      {filteredItems.map((item, index) => (
        <ContextSelectorItem key={index}>
          {item || 'no arch'}
        </ContextSelectorItem>
      ))}
    </ContextSelector>
  );
};

GenericSelector.propTypes = {
  selectionItems: PropTypes.array,
  setGlobalSelected: PropTypes.func.isRequired,
  screenReaderLabel: PropTypes.string,
  initialLabel: PropTypes.string,
};

GenericSelector.defaultProps = {
  selectionItems: [],
  screenReaderLabel: '',
  initialLabel: '',
};

export default GenericSelector;
