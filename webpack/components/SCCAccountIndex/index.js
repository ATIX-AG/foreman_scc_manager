import React, { useState, useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import {
  PageSection,
  Modal,
  Button,
  Dropdown,
  DropdownList,
  DropdownItem,
  MenuToggle,
} from '@patternfly/react-core';
import { Table, Thead, Tr, Th, Td, Tbody } from '@patternfly/react-table';
import { EllipsisVIcon } from '@patternfly/react-icons';
import { useDispatch } from 'react-redux';
import { translate as __ } from 'foremanReact/common/I18n';
import { foremanUrl } from 'foremanReact/common/helpers';
import { WARN_DELETE } from './SCCAccountIndexConstants';
import {
  syncSccAccountAction,
  deleteSccAccountAction,
} from './SCCAccountIndexActions';
import './SCCAccountIndex.scss';

function SccAccountsIndex({ initialAccounts }) {
  const dispatch = useDispatch();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [openMenuRow, setOpenMenuRow] = useState(null);
  const [accounts, setAccounts] = useState(initialAccounts);
  const [selectedAccountName, setSelectedAccountName] = useState(null);
  const deletingIdRef = useRef(null);
  const taskTimeoutRef = useRef({});
  const lastStateRef = useRef({});

  const handleSync = (accountId) => {
    syncSccAccountAction(
      dispatch,
      accountId,
      setAccounts,
      taskTimeoutRef,
      lastStateRef
    );
  };

  const handleDelete = (id) => {
    deleteSccAccountAction(
      dispatch,
      id,
      setAccounts,
      setDeleteOpen,
      deletingIdRef
    );
  };

  useEffect(
    () => () => {
      Object.values(taskTimeoutRef.current).forEach(clearTimeout);
      taskTimeoutRef.current = {};
    },
    []
  );

  return (
    <PageSection ouiaId="scc-accounts-index-page-section">
      <div className="scc-account-add-container">
        <Button
          component="a"
          href={foremanUrl('/scc_accounts/new')}
          variant="primary"
          ouiaId="scc-account-add-button"
        >
          {__('Add SCC account')}
        </Button>
      </div>

      <Table
        aria-label={__('SUSE subscriptions')}
        ouiaId="scc-accounts-table"
        variant="compact"
      >
        <Thead ouiaId="scc-accounts-table-head">
          <Tr ouiaId="scc-accounts-table-header-row">
            <Th ouiaId="scc-accounts-name-header">{__('Name')}</Th>
            <Th ouiaId="scc-accounts-products-header">{__('Products')}</Th>
            <Th ouiaId="scc-accounts-last-synced-header">
              {__('Last synced')}
            </Th>
            <Th width={10} ouiaId="scc-accounts-actions-header">
              {__('Actions')}
            </Th>
          </Tr>
        </Thead>
        <Tbody ouiaId="scc-accounts-table-body">
          {accounts &&
            accounts.map((acc) => {
              const lastSynced = acc.sync_task ? (
                <a
                  target="_blank"
                  href={foremanUrl(`/foreman_tasks/tasks/${acc.sync_task.id}`)}
                  rel="noreferrer"
                >
                  {acc.sync_status}
                </a>
              ) : (
                acc.sync_status || __('never synced')
              );

              return (
                <Tr key={acc.id} ouiaId={`scc-account-row-${acc.id}`}>
                  <Td
                    dataLabel={__('Name')}
                    ouiaId={`scc-account-name-${acc.id}`}
                  >
                    <a href={`/scc_accounts/${acc.id}/edit`}>{acc.name}</a>
                  </Td>
                  <Td
                    dataLabel={__('Products')}
                    ouiaId={`scc-account-products-${acc.id}`}
                  >
                    {acc.scc_products_with_repos_count}
                  </Td>

                  <Td
                    dataLabel={__('Last synced')}
                    ouiaId={`scc-account-last-synced-${acc.id}`}
                  >
                    {lastSynced}
                  </Td>
                  <Td
                    dataLabel={__('Actions')}
                    ouiaId={`scc-account-actions-${acc.id}`}
                  >
                    <div className="scc-account-actions">
                      <Button
                        variant="primary"
                        size="sm"
                        onClick={() => {
                          window.location.href = `/scc_accounts/${acc.id}`;
                        }}
                        ouiaId={`scc-account-select-products-button-${acc.id}`}
                      >
                        {__('Select Products')}
                      </Button>

                      <Dropdown
                        isOpen={openMenuRow === acc.id}
                        onSelect={() => setOpenMenuRow(null)}
                        onOpenChange={(isOpen) =>
                          setOpenMenuRow(isOpen ? acc.id : null)
                        }
                        ouiaId={`scc-account-actions-dropdown-${acc.id}`}
                        toggle={(toggleRef) => (
                          <MenuToggle
                            ref={toggleRef}
                            aria-label={__('Actions menu')}
                            variant="plain"
                            isExpanded={openMenuRow === acc.id}
                            onClick={() =>
                              setOpenMenuRow(
                                openMenuRow === acc.id ? null : acc.id
                              )
                            }
                            ouiaId={`scc-account-actions-menu-toggle-${acc.id}`}
                          >
                            <EllipsisVIcon />
                          </MenuToggle>
                        )}
                      >
                        <DropdownList
                          ouiaId={`scc-account-actions-dropdown-list-${acc.id}`}
                        >
                          <DropdownItem
                            key="sync"
                            isDisabled={
                              acc.sync_status === 'running' ||
                              acc.sync_status === 'planned'
                            }
                            onClick={() => {
                              setOpenMenuRow(null);
                              handleSync(acc.id);
                            }}
                            ouiaId={`scc-account-sync-item-${acc.id}`}
                          >
                            {acc.sync_status === 'running' ||
                            acc.sync_status === 'planned'
                              ? __('Syncing...')
                              : __('Sync')}
                          </DropdownItem>

                          <DropdownItem
                            key="delete"
                            onClick={() => {
                              setOpenMenuRow(null);
                              deletingIdRef.current = acc.id;
                              setDeleteOpen(true);
                              setSelectedAccountName(acc.name);
                            }}
                            ouiaId={`scc-account-delete-item-${acc.id}`}
                          >
                            {__('Delete')}
                          </DropdownItem>
                        </DropdownList>
                      </Dropdown>
                    </div>
                  </Td>
                </Tr>
              );
            })}
        </Tbody>
      </Table>

      <Modal
        title={__('Delete SCC Account')}
        isOpen={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        variant="small"
        ouiaId="scc-account-delete-modal"
        actions={[
          <Button
            key="confirm"
            variant="danger"
            onClick={() => handleDelete(deletingIdRef.current)}
            ouiaId="scc-account-delete-confirm-button"
          >
            {__('Delete')}
          </Button>,
          <Button
            key="cancel"
            variant="link"
            onClick={() => setDeleteOpen(false)}
            ouiaId="scc-account-delete-cancel-button"
          >
            {__('Cancel')}
          </Button>,
        ]}
      >
        <div className="scc-account-delete-warning">
          {WARN_DELETE.replace('%acc_name', selectedAccountName || '')}
        </div>
      </Modal>
    </PageSection>
  );
}

SccAccountsIndex.propTypes = {
  initialAccounts: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      sync_status: PropTypes.string,
      sync_task: PropTypes.shape({
        id: PropTypes.string,
      }),
      scc_products_with_repos_count: PropTypes.number,
    })
  ),
};

SccAccountsIndex.defaultProps = {
  initialAccounts: [],
};

export default SccAccountsIndex;
