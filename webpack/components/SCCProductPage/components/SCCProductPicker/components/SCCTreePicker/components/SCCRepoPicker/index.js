import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import {
  Select,
  SelectOption,
  SelectList,
  MenuToggle,
} from '@patternfly/react-core';

import './styles.scss';

const createRepoSelectOption = (repo, disableRepos, selectedItems) => (
  <SelectOption
    hasCheckbox
    key={repo.id}
    isDisabled={repo.katello_repository_id !== null || disableRepos}
    value={repo.name}
    isSelected={selectedItems.includes(repo.name)}
  >
    {repo.name}
  </SelectOption>
);

const setRepoSelection = (
  sccRepos,
  disableRepos,
  activateDebugFilter,
  productAlreadySynced
) => {
  let res = [];
  // this is necessary because the logic of this option was inverted
  // Instead of filtering the debug repositories with the corresponding option,
  // this option now includes the repositories, instead - means, it does exactly the opposite.
  activateDebugFilter = !activateDebugFilter;
  if (!disableRepos && !productAlreadySynced) {
    if (activateDebugFilter) {
      res = sccRepos.filter(
        (repo) =>
          (!repo.name.includes('Debug') &&
            !repo.name.includes('-Source') &&
            repo.katello_repository_id === null) ||
          repo.katello_repository_id !== null
      );
    } else {
      res = sccRepos;
    }
  } else {
    res = sccRepos.filter((repo) => repo.katello_repository_id !== null);
  }
  return res.map((repo) => repo.name);
};

// disableRepos makes sure that repos can only be selected if the corresponding product
// is also selected
const SCCRepoPicker = ({
  sccRepos,
  disableRepos,
  activateDebugFilter,
  productAlreadySynced,
  sccProductId,
  sccProductName,
  setSelectedReposFromChild,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  // set initial selected values to the already checked repos
  const [selected, setSelected] = useState(
    setRepoSelection(
      sccRepos,
      disableRepos,
      activateDebugFilter,
      productAlreadySynced
    )
  );

  const onToggleClick = () => {
    setIsOpen(!isOpen);
  };

  useEffect(() => {
    const selectedRepos = setRepoSelection(
      sccRepos,
      disableRepos,
      activateDebugFilter,
      productAlreadySynced
    );
    setSelected(selectedRepos);
    setSelectedReposFromChild(
      sccProductId,
      sccProductName,
      sccRepos
        // make sure that we do not request already subscribed repositories
        .filter(
          (repo) =>
            selectedRepos.includes(repo.name) &&
            repo.katello_repository_id === null
        )
        .map((repo) => repo.id),
      sccRepos
        // make sure that we do not request already subscribed repositories
        .filter(
          (repo) =>
            selectedRepos.includes(repo.name) &&
            repo.katello_repository_id === null
        )
        .map((repo) => repo.name)
    );
  }, [
    sccRepos,
    disableRepos,
    activateDebugFilter,
    productAlreadySynced,
    sccProductId,
    setSelectedReposFromChild,
  ]);

  const onSelect = (event, selection) => {
    let selectedRepos = [];
    if (event.target.checked) {
      selectedRepos = [...new Set(selected.concat([selection]))];
    } else {
      selectedRepos = selected.filter((item) => item !== selection);
    }
    setSelected(selectedRepos);
    setSelectedReposFromChild(
      sccProductId,
      sccProductName,
      sccRepos
        // make sure that we do not request already subscribed repositories
        .filter(
          (repo) =>
            selectedRepos.includes(repo.name) &&
            repo.katello_repository_id === null
        )
        .map((repo) => repo.id),
      sccRepos
        // make sure that we do not request already subscribed repositories
        .filter(
          (repo) =>
            selectedRepos.includes(repo.name) &&
            repo.katello_repository_id === null
        )
        .map((repo) => repo.name)
    );
  };

  const selectOptions = sccRepos.map((repo) =>
    createRepoSelectOption(repo, disableRepos, selected)
  );

  const toggle = (toggleRef) => (
    <MenuToggle ref={toggleRef} onClick={onToggleClick} isExpanded={isOpen}>
      {sprintf(__('%s/%s'), selected.length, sccRepos.length)}
    </MenuToggle>
  );

  return (
    <Select
      ouiaId={sccProductId.toString().concat('scc-manager-repo-picker')}
      toggle={toggle}
      onSelect={onSelect}
      selections={selected}
      isOpen={isOpen}
      onOpenChange={(nextOpen) => setIsOpen(nextOpen)}
    >
      <SelectList>{selectOptions}</SelectList>
    </Select>
  );
};

SCCRepoPicker.propTypes = {
  sccRepos: PropTypes.array,
  disableRepos: PropTypes.bool,
  activateDebugFilter: PropTypes.bool,
  productAlreadySynced: PropTypes.bool,
  sccProductId: PropTypes.number.isRequired,
  sccProductName: PropTypes.string.isRequired,
  setSelectedReposFromChild: PropTypes.func.isRequired,
};

SCCRepoPicker.defaultProps = {
  sccRepos: [],
  disableRepos: false,
  activateDebugFilter: false,
  productAlreadySynced: false,
};

export default SCCRepoPicker;
