import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { Flex, FlexItem, Select, SelectOption } from '@patternfly/react-core';

const SCCGenericExpander = ({
  setInParent,
  selectOptionOpen,
  selectOptionClose,
  initLabel,
}) => {
  const [label, setLabel] = useState(initLabel);
  const [isOpen, setIsOpen] = useState(false);

  const options = [
    <SelectOption key={0} value={selectOptionOpen} />,
    <SelectOption key={1} value={selectOptionClose} />,
  ];

  const onSelect = (evt, selection) => {
    if (selection === selectOptionOpen) {
      setInParent(true);
    } else {
      setInParent(false);
    }
    setLabel(selection);
    setIsOpen(false);
  };

  const onToggle = (isOpenSelect) => {
    setIsOpen(isOpenSelect);
  };

  return (
    <Flex>
      <FlexItem>
        <Select
          onToggle={onToggle}
          onSelect={onSelect}
          selections={label}
          isOpen={isOpen}
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
