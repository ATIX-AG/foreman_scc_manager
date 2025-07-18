/* eslint no-nested-ternary: "off" */
import { foremanUrl } from 'foremanReact/common/helpers';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';

import PropTypes from 'prop-types';
import React, { useState } from 'react';
import {
  Tooltip,
  Dropdown,
  DropdownItem,
  DropdownList,
  MenuToggle,
} from '@patternfly/react-core';
import { Icon } from 'patternfly-react';
import { BrowserRouter, Link } from 'react-router-dom';

import './styles.scss';

const createKatelloRepoLink = (repo, sccProductId) => {
  const url = foremanUrl(
    `/products/${sccProductId}/repositories/${repo.katello_repository_id}`
  );
  return (
    <Tooltip
      key={'scc-manager-repo-view-tooltip-'.concat(repo.id)}
      content={__('Go to Repository page')}
    >
      <BrowserRouter>
        <Link to={url} target="_blank">
          {repo.name}
        </Link>
      </BrowserRouter>
    </Tooltip>
  );
};

const createRepoDropDownItem = (repo, sccProductId) => (
  <DropdownItem
    key={repo.id}
    ouiaId={repo.id}
    component="button"
    icon={
      repo.subscription_valid ? (
        repo.katello_repository_id !== null ? (
          <Icon name="check" type="fa" />
        ) : (
          <Tooltip
            key={'scc-manager-repo-link-tooltip-'.concat(repo.id)}
            content={__('Repository not imported')}
          >
            <Icon name="ban" type="fa" />
          </Tooltip>
        )
      ) : (
        <Tooltip
          key={'scc-manager-repo-link-tooltip-'.concat(repo.id)}
          content={__('Please check your SUSE subscription')}
        >
          <Icon name="warning-triangle-o" type="pf" size="2x" />
        </Tooltip>
      )
    }
  >
    {repo.katello_repository_id !== null
      ? createKatelloRepoLink(repo, sccProductId)
      : repo.name}
  </DropdownItem>
);

const SCCRepoView = ({ sccRepos, sccProductId }) => {
  const [isOpen, setIsOpen] = useState(false);
  const onToggleClick = () => {
    setIsOpen(!isOpen);
  };

  const onFocus = () => {
    const element = document.getElementById(
      sprintf('scc-repo-show-toggle-id-%s', sccProductId)
    );
    element.focus();
  };

  const onSelect = (event) => {
    setIsOpen(false);
    onFocus();
  };

  const dropdownItems = sccRepos.map((repo) =>
    createRepoDropDownItem(repo, sccProductId)
  );

  const toggle = (toggleRef) => (
    <MenuToggle ref={toggleRef} onClick={onToggleClick} isExpanded={isOpen}>
      {sprintf(
        __('Repositories (%s/%s)'),
        sccRepos.filter((r) => r.katello_repository_id !== null).length,
        sccRepos.length
      )}
    </MenuToggle>
  );

  return (
    <Dropdown
      ouiaId={sccProductId?.toString().concat('scc-manager-repo-view')}
      onClick={onToggleClick}
      onSelect={onSelect}
      toggle={toggle}
      isOpen={isOpen}
      onOpenChange={(isOpenMenu) => setIsOpen(isOpenMenu)}
    >
      <DropdownList>{dropdownItems}</DropdownList>
    </Dropdown>
  );
};

SCCRepoView.propTypes = {
  sccRepos: PropTypes.array,
  sccProductId: PropTypes.number,
};

SCCRepoView.defaultProps = {
  sccRepos: undefined,
  sccProductId: undefined,
};

export default SCCRepoView;
