/* eslint-disable react/prop-types, global-require */
import React from 'react';
import '@testing-library/jest-dom';
import {
  render,
  screen,
  within,
  fireEvent,
  waitFor,
} from '@testing-library/react';

import SccAccountsIndex from './index';
import { deleteSccAccountAction } from './SCCAccountIndexActions';

jest.mock('foremanReact/common/I18n', () => ({ translate: (s) => s }), {
  virtual: true,
});
jest.mock('foremanReact/common/helpers', () => ({ foremanUrl: (p) => p }), {
  virtual: true,
});
jest.mock('react-redux', () => ({ useDispatch: () => jest.fn() }), {
  virtual: true,
});

jest.mock(
  './SCCAccountIndexActions',
  () => ({
    deleteSccAccountAction: jest.fn(),
  }),
  { virtual: true }
);

jest.mock(
  '@patternfly/react-core',
  () => {
    const { forwardRef } = require('react');
    const PageSection = ({ children }) => <section>{children}</section>;

    const Button = ({
      children,
      onClick,
      component,
      href,
      'aria-label': ariaLabel,
    }) => {
      if (component === 'a') {
        return (
          <a href={href} onClick={onClick} aria-label={ariaLabel}>
            {children}
          </a>
        );
      }
      return (
        <button type="button" onClick={onClick} aria-label={ariaLabel}>
          {children}
        </button>
      );
    };

    const Dropdown = ({ isOpen, onSelect, onOpenChange, toggle, children }) => (
      <div>
        {typeof toggle === 'function' ? toggle({ current: null }) : null}
        {isOpen ? (
          <div data-testid="menu">
            {children}
            <button
              type="button"
              aria-label="Close menu"
              onClick={() => {
                if (onSelect) onSelect();
                if (onOpenChange) onOpenChange(false);
              }}
            />
          </div>
        ) : null}
      </div>
    );

    const DropdownList = ({ children }) => <div role="menu">{children}</div>;

    const DropdownItem = ({ children, onClick, isDisabled }) => (
      <div
        role="menuitem"
        aria-disabled={!!isDisabled}
        onClick={(e) => {
          if (!isDisabled && onClick) onClick(e);
        }}
      >
        {children}
      </div>
    );

    const MenuToggle = forwardRef(
      ({ children, onClick, 'aria-label': ariaLabel }, ref) => (
        <button
          ref={ref}
          type="button"
          aria-label={ariaLabel}
          onClick={onClick}
        >
          {children}
        </button>
      )
    );

    const Modal = ({ title, isOpen, children, actions }) =>
      isOpen ? (
        <div role="dialog" aria-label={title}>
          <h2>{title}</h2>
          {children}
          {Array.isArray(actions) &&
            actions.map((node, i) => <div key={i}>{node}</div>)}
        </div>
      ) : null;

    return {
      __esModule: true,
      PageSection,
      Button,
      Dropdown,
      DropdownList,
      DropdownItem,
      MenuToggle,
      Modal,
    };
  },
  { virtual: true }
);

jest.mock(
  '@patternfly/react-table',
  () => ({
    __esModule: true,
    Table: ({ children, ..._rest }) => <table>{children}</table>,
    Thead: ({ children }) => <thead>{children}</thead>,
    Tbody: ({ children }) => <tbody>{children}</tbody>,
    Tr: ({ children }) => <tr>{children}</tr>,
    Th: ({ children }) => <th>{children}</th>,
    Td: ({ children }) => <td>{children}</td>,
  }),
  { virtual: true }
);

// Helpers
const renderComponent = (initialAccounts = []) =>
  render(<SccAccountsIndex initialAccounts={initialAccounts} />);

const openActionsMenu = () => {
  fireEvent.click(screen.getByLabelText('Actions menu'));
  return screen.getByTestId('menu');
};

const getRowByAccountName = (name) =>
  screen.getByRole('row', { name: new RegExp(name, 'i') });

// Tests
describe('SccAccountsIndex', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders without crashing and shows the Add button', () => {
    renderComponent();
    expect(screen.getByText('Add SCC account')).toBeInTheDocument();
  });

  it('shows expected table headers', () => {
    renderComponent();
    ['Name', 'Products', 'Last synced', 'Actions'].forEach((h) => {
      expect(screen.getByText(h)).toBeInTheDocument();
    });
  });

  it('renders rows from props (names + product counts) with edit links', () => {
    const data = [
      { id: 1, name: 'Acc A', scc_products_with_repos_count: 2 },
      { id: 2, name: 'Acc B', scc_products_with_repos_count: 5 },
    ];
    renderComponent(data);

    expect(screen.getByRole('link', { name: 'Acc A' })).toHaveAttribute(
      'href',
      '/scc_accounts/1/edit'
    );
    expect(screen.getByRole('link', { name: 'Acc B' })).toHaveAttribute(
      'href',
      '/scc_accounts/2/edit'
    );

    const rowA = getRowByAccountName('Acc A');
    const rowB = getRowByAccountName('Acc B');
    expect(within(rowA).getByText('2')).toBeInTheDocument();
    expect(within(rowB).getByText('5')).toBeInTheDocument();
  });

  it('shows correct "Last synced" content: link when task exists, "never synced" otherwise', () => {
    const data = [
      {
        id: 10,
        name: 'Successful Sync',
        scc_products_with_repos_count: 1,
        sync_status: 'success',
        sync_task: { id: 'task-123' },
      },
      {
        id: 11,
        name: 'Failed Sync',
        scc_products_with_repos_count: 0,
        sync_status: 'error',
        sync_task: { id: 'task-456' },
      },
      {
        id: 12,
        name: 'No Sync',
        scc_products_with_repos_count: 0,
        sync_status: null,
      },
    ];
    renderComponent(data);

    const successRow = getRowByAccountName('Successful Sync');
    expect(
      within(successRow).getByRole('link', { name: 'success' })
    ).toHaveAttribute('href', '/foreman_tasks/tasks/task-123');

    const errorRow = getRowByAccountName('Failed Sync');
    expect(
      within(errorRow).getByRole('link', { name: 'error' })
    ).toHaveAttribute('href', '/foreman_tasks/tasks/task-456');

    const noSyncRow = getRowByAccountName('No Sync');
    expect(within(noSyncRow).getByText('never synced')).toBeInTheDocument();
  });

  it('delete flow: open modal, confirm calls action, cancel closes modal', async () => {
    const data = [
      {
        id: 5,
        name: 'ToDelete',
        scc_products_with_repos_count: 0,
        sync_status: 'never synced',
      },
    ];
    renderComponent(data);

    const menu = openActionsMenu();
    fireEvent.click(within(menu).getByRole('menuitem', { name: 'Delete' }));

    const dialog = screen.getByRole('dialog');
    fireEvent.click(within(dialog).getByRole('button', { name: 'Delete' }));

    expect(deleteSccAccountAction).toHaveBeenCalledWith(
      expect.any(Function), // dispatch
      5, // accountId
      expect.any(Function), // setAccounts
      expect.any(Function), // setDeleteOpen
      expect.any(Object) // deletingIdRef
    );

    fireEvent.click(
      within(screen.getByRole('dialog')).getByRole('button', { name: 'Cancel' })
    );
    await waitFor(() =>
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    );

    const menu2 = openActionsMenu();
    fireEvent.click(within(menu2).getByRole('menuitem', { name: 'Delete' }));
    fireEvent.click(
      within(screen.getByRole('dialog')).getByRole('button', { name: 'Cancel' })
    );
    await waitFor(() =>
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    );
  });

  it('empty state: renders headers and no data rows', () => {
    renderComponent([]);

    ['Name', 'Products', 'Last synced', 'Actions'].forEach((h) => {
      expect(screen.getByText(h)).toBeInTheDocument();
    });

    expect(screen.getAllByRole('row')).toHaveLength(1);

    expect(screen.queryByLabelText('Actions menu')).not.toBeInTheDocument();
    expect(
      screen.queryByRole('button', { name: 'Select Products' })
    ).not.toBeInTheDocument();
  });
});
