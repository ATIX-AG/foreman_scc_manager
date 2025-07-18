import React, { useState } from 'react';
import PropTypes from 'prop-types';
import {
  Flex,
  FlexItem,
  Select,
  SelectList,
  MenuToggle,
  SelectOption,
} from '@patternfly/react-core';

const SCCGenericExpander = ({
  setInParent,
  selectOptionOpen,
  selectOptionClose,
  initLabel,
}) => {
  const [label, setLabel] = useState(initLabel);
  const [isOpen, setIsOpen] = useState(false);

  const options = (
    <SelectList>
      <SelectOption value={selectOptionOpen}>{selectOptionOpen}</SelectOption>
      <SelectOption value={selectOptionClose}>{selectOptionClose}</SelectOption>
    </SelectList>
  );

  const onSelect = (_evt, selection) => {
    if (selection === selectOptionOpen) {
      setInParent(true);
    } else {
      setInParent(false);
    }
    setLabel(selection);
    setIsOpen(false);
  };

  const onToggleClick = () => {
    setIsOpen(!isOpen);
  };

  const toggle = (toggleRef) => (
    <MenuToggle ref={toggleRef} onClick={onToggleClick} isExpanded={isOpen}>
      {label}
    </MenuToggle>
  );

  return (
    <Flex>
      <FlexItem>
        <Select
          ouiaId={initLabel.concat('scc-manager-generic-expander-select')}
          toggle={toggle}
          onSelect={onSelect}
          selected={label}
          isOpen={isOpen}
          onOpenChange={(nextOpen) => setIsOpen(isOpen)}
          shouldFocusToggleOnSelect
        >
          {options}
        </Select>
      </FlexItem>
    </Flex>
  );
};

SCCGenericExpander.propTypes = {
  setInParent: PropTypes.func.isRequired,
  selectOptionOpen: PropTypes.string.isRequired,
  selectOptionClose: PropTypes.string.isRequired,
  initLabel: PropTypes.string.isRequired,
};

SCCGenericExpander.deaultProps = {};

export default SCCGenericExpander;
