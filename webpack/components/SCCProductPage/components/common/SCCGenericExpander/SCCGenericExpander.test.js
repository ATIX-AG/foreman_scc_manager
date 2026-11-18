import React from 'react';
import { act, fireEvent, render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SCCGenericExpander from './index';

describe('SCCGenericExpander', () => {
  it('renders the toggle and available options', async () => {
    render(
      <SCCGenericExpander
        setInParent={() => {}}
        selectOptionOpen="open"
        selectOptionClose="close"
        initLabel="open/close"
        ouiaId="test-"
      />
    );

    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'open/close' }));
    });

    expect(screen.getByText('open', { exact: true })).toBeInTheDocument();
    expect(screen.getByText('close', { exact: true })).toBeInTheDocument();
  });

  it('updates the parent and toggle label when an option is selected', async () => {
    const setInParent = jest.fn();
    render(
      <SCCGenericExpander
        setInParent={setInParent}
        selectOptionOpen="open"
        selectOptionClose="close"
        initLabel="open/close"
        ouiaId="test-"
      />
    );

    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'open/close' }));
    });
    fireEvent.click(screen.getByText('open', { exact: true }));

    expect(setInParent).toHaveBeenCalledWith(true);
    expect(screen.getByRole('button', { name: 'open' })).toBeInTheDocument();
  });
});
