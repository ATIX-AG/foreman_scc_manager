/* eslint-disable react/prop-types, import/no-unresolved */
import React from 'react';
import '@testing-library/jest-dom';
import { fireEvent, render, screen, within } from '@testing-library/react';

import SCCProductPickerModal from './index';

describe('SCCProductPickerModal', () => {
  const defaultProps = {
    isOpen: true,
    onClose: jest.fn(),
    taskId: 'task-123',
    reposToSubscribe: [
      {
        productName: 'SLES',
        repoNames: ['Repo A', 'Repo B'],
      },
      {
        productName: 'Tools',
        repoNames: ['Repo C'],
      },
    ],
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('does not render when closed', () => {
    render(<SCCProductPickerModal {...defaultProps} isOpen={false} />);

    expect(
      screen.queryByRole('dialog', {
        name: 'Summary of SCC product subscription',
      })
    ).not.toBeInTheDocument();
  });

  it('renders the subscription summary, task link, and imported products', () => {
    render(<SCCProductPickerModal {...defaultProps} />);

    const dialog = screen.getByRole('dialog', {
      name: 'Summary of SCC product subscription',
    });

    expect(
      within(dialog).getByText(/The subscription task with id/i)
    ).toBeInTheDocument();
    expect(
      within(dialog).getByRole('link', { name: 'task-123' })
    ).toHaveAttribute('href', '/foreman_tasks/tasks/task-123');
    expect(
      within(dialog).getByText('The following products will be imported:')
    ).toBeInTheDocument();
    expect(within(dialog).getByText('SLES')).toBeInTheDocument();
    expect(within(dialog).getByText('Repo A')).toBeInTheDocument();
    expect(within(dialog).getByText('Repo B')).toBeInTheDocument();
    expect(within(dialog).getByText('Tools')).toBeInTheDocument();
    expect(within(dialog).getByText('Repo C')).toBeInTheDocument();
  });

  it('calls onClose when the modal is closed', () => {
    render(<SCCProductPickerModal {...defaultProps} />);

    fireEvent.click(screen.getByRole('button', { name: 'Close' }));

    expect(defaultProps.onClose).toHaveBeenCalledTimes(1);
  });
});
