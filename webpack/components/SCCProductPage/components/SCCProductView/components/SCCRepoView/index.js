/* eslint no-nested-ternary: "off" */
import { foremanUrl } from 'foremanReact/common/helpers';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';

import PropTypes from 'prop-types';
import React, { useState } from 'react';
import {
  Dropdown,
  DropdownItem,
  BadgeToggle,
  Tooltip,
} from '@patternfly/react-core';
import { Icon } from 'patternfly-react';
import { BrowserRouter, Link } from 'react-router-dom';

import './styles.scss';

const createKatelloRepoLink = (repo, sccProductId) => {
  const url = foremanUrl(
    `/products/${sccProductId}/repositories/${repo.katello_repository_id}`
  );
  return (
    <Tooltip content={__('Go to Repository page')}>
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
    component="button"
    icon={
      repo.subscription_valid ? (
        repo.katello_repository_id !== null ? (
          <Icon name="check" type="fa" />
        ) : (
          <Tooltip content={__('Repository not imported')}>
            <Icon name="ban" type="fa" />
          </Tooltip>
        )
      ) : (
        <Tooltip content={__('Please check your SUSE subscription')}>
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
  const onToggle = (toggle) => {
    setIsOpen(toggle);
  };

  const onFocus = () => {
    const element = document.getElementById(
      sprintf('scc-repo-show-toggle-id-%s', sccProductId)
    );
    element.focus();
  };

  const onSelect = (event) => {
    setIsOpen(!isOpen);
    onFocus();
  };

  const dropdownItems = sccRepos.map((repo) =>
    createRepoDropDownItem(repo, sccProductId)
  );

  return (
    <Dropdown
      onSelect={onSelect}
      toggle={
        <BadgeToggle
          id={sprintf('scc-repo-show-toggle-id-%s', sccProductId)}
          key={sprintf('scc-repo-show-toggle-id-%s', sccProductId)}
          onToggle={onToggle}
        >
          {sprintf(
            __('Repositories (%s/%s)'),
            sccRepos.filter((r) => r.katello_repository_id !== null).length,
            sccRepos.length
          )}
        </BadgeToggle>
      }
      isOpen={isOpen}
      dropdownItems={dropdownItems}
    />
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
