// Reference: https://v5-archive.patternfly.org/components/menus/select#typeahead

import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Select,
  SelectOption,
  SelectList,
  MenuToggle,
  TextInputGroup,
  TextInputGroupMain,
  TextInputGroupUtilities,
  Button,
} from '@patternfly/react-core';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
import { translate as __ } from 'foremanReact/common/I18n';

const GenericSelector = ({
  initialSelectOptions,
  setSelected,
  initialLabel,
  selected,
  inputValue,
  setInputValue,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [filterValue, setFilterValue] = useState('');
  const [selectOptions, setSelectOptions] = useState(
    initialSelectOptions.map((option) => ({
      children: option,
      value: option,
    }))
  );
  const [focusedItemIndex, setFocusedItemIndex] = useState(null);
  const [activeItemId, setActiveItemId] = useState(null);
  const NO_RESULTS = __('no results');

  useEffect(() => {
    let newSelectOptions = initialSelectOptions.map((option) => ({
      children: option,
      value: option,
    }));
    if (filterValue) {
      newSelectOptions = newSelectOptions.filter((menuItem) =>
        String(menuItem.children)
          .toLowerCase()
          .includes(filterValue.toLowerCase())
      );
      if (!newSelectOptions.length) {
        newSelectOptions = [
          {
            isAriaDisabled: true,
            children: `No results found for "${filterValue}"`,
            value: NO_RESULTS,
          },
        ];
      }
      if (!isOpen) {
        setIsOpen(true);
      }
    }
    setSelectOptions(newSelectOptions);
  }, [filterValue, initialSelectOptions]);
  const createItemId = (value) =>
    `select-typeahead-${value?.replace(' ', '-')}`;
  const setActiveAndFocusedItem = (itemIndex) => {
    setFocusedItemIndex(itemIndex);
    const focusedItem = selectOptions[itemIndex];
    setActiveItemId(createItemId(focusedItem.value));
  };
  const resetActiveAndFocusedItem = () => {
    setFocusedItemIndex(null);
    setActiveItemId(null);
  };
  const closeMenu = () => {
    setIsOpen(false);
    resetActiveAndFocusedItem();
  };
  const onInputClick = () => {
    if (!isOpen) {
      setIsOpen(true);
    } else if (!inputValue) {
      closeMenu();
    }
  };
  const selectOption = (value, content) => {
    setInputValue(String(content));
    setFilterValue('');
    setSelected(String(value));
    closeMenu();
  };
  const onSelect = (_event, value) => {
    if (value && value !== NO_RESULTS) {
      const optionText = selectOptions.find((option) => option.value === value)
        ?.children;
      selectOption(value, optionText);
    }
  };
  const onTextInputChange = (_event, value) => {
    setInputValue(value);
    setFilterValue(value);
    resetActiveAndFocusedItem();
    if (value !== selected) {
      setSelected('');
    }
  };
  const handleMenuArrowKeys = (key) => {
    let indexToFocus = 0;
    if (!isOpen) {
      setIsOpen(true);
    }
    if (selectOptions.every((option) => option.isDisabled)) {
      return;
    }
    if (key === 'ArrowUp') {
      if (focusedItemIndex === null || focusedItemIndex === 0) {
        indexToFocus = selectOptions.length - 1;
      } else {
        indexToFocus = focusedItemIndex - 1;
      }
      while (selectOptions[indexToFocus].isDisabled) {
        indexToFocus--;
        if (indexToFocus === -1) {
          indexToFocus = selectOptions.length - 1;
        }
      }
    }
    if (key === 'ArrowDown') {
      if (
        focusedItemIndex === null ||
        focusedItemIndex === selectOptions.length - 1
      ) {
        indexToFocus = 0;
      } else {
        indexToFocus = focusedItemIndex + 1;
      }
      while (selectOptions[indexToFocus].isDisabled) {
        indexToFocus++;
        if (indexToFocus === selectOptions.length) {
          indexToFocus = 0;
        }
      }
    }
    setActiveAndFocusedItem(indexToFocus);
  };
  const onInputKeyDown = (event) => {
    const focusedItem =
      focusedItemIndex !== null ? selectOptions[focusedItemIndex] : null;
    switch (event.key) {
      case 'Enter':
        if (
          isOpen &&
          focusedItem &&
          focusedItem.value !== NO_RESULTS &&
          !focusedItem.isAriaDisabled
        ) {
          selectOption(focusedItem.value, focusedItem.children);
        }
        if (!isOpen) {
          setIsOpen(true);
        }
        break;
      case 'ArrowUp':
      case 'ArrowDown':
        event.preventDefault();
        handleMenuArrowKeys(event.key);
        break;
      default:
        break;
    }
  };
  const onToggleClick = () => {
    setIsOpen(!isOpen);
  };
  const onClearButtonClick = () => {
    setSelected('');
    setInputValue('');
    setFilterValue('');
    resetActiveAndFocusedItem();
  };
  const toggle = (toggleRef) => (
    <MenuToggle
      ref={toggleRef}
      variant="typeahead"
      onClick={onToggleClick}
      isExpanded={isOpen}
      isFullWidth
    >
      <TextInputGroup isPlain>
        <TextInputGroupMain
          value={inputValue}
          onClick={onInputClick}
          onChange={onTextInputChange}
          onKeyDown={onInputKeyDown}
          id={initialLabel.concat('typeahead-select-input')}
          autoComplete="off"
          placeholder={initialLabel}
          {...(activeItemId && {
            'aria-activedescendant': activeItemId,
          })}
          role="combobox"
          isExpanded={isOpen}
        />

        <TextInputGroupUtilities
          {...(!inputValue
            ? {
                style: {
                  display: 'none',
                },
              }
            : {})}
        >
          <Button
            variant="plain"
            ouiaId={initialLabel.concat('scc-product-picker-button')}
            onClick={onClearButtonClick}
          >
            <TimesIcon aria-hidden />
          </Button>
        </TextInputGroupUtilities>
      </TextInputGroup>
    </MenuToggle>
  );
  return (
    <Select
      id={initialLabel}
      ouiaId={initialLabel.concat('scc-product-picker-select')}
      isOpen={isOpen}
      selected={selected}
      onSelect={onSelect}
      onOpenChange={(isOpenSelect) => {
        !isOpenSelect && closeMenu();
      }}
      toggle={toggle}
      shouldFocusFirstItemOnOpen={false}
    >
      <SelectList id={initialLabel.concat('select-typeahead-listbox')}>
        {selectOptions.map((option, index) => (
          <SelectOption
            key={option.value || option.children}
            isFocused={focusedItemIndex === index}
            id={createItemId(option.value)}
            className={option.className}
            {...option}
            ref={null}
          />
        ))}
      </SelectList>
    </Select>
  );
};

GenericSelector.propTypes = {
  initialSelectOptions: PropTypes.array,
  initialLabel: PropTypes.string,
  selected: PropTypes.string.isRequired,
  setSelected: PropTypes.func.isRequired,
  inputValue: PropTypes.string.isRequired,
  setInputValue: PropTypes.func.isRequired,
};

GenericSelector.defaultProps = {
  initialSelectOptions: [],
  initialLabel: '',
};

export default GenericSelector;
