/* eslint-disable react/prop-types */
import React from 'react';
import { render, screen } from '@testing-library/react';
import GenericSelector from './components/SCCProductPicker/components/SCCGenericPicker';
import SCCRepoPicker from './components/SCCProductPicker/components/SCCTreePicker/components/SCCRepoPicker';
import SCCRepoView from './components/SCCProductView/components/SCCRepoView';
import SCCGenericExpander from './components/common/SCCGenericExpander';
import SCCProductTreeExpander from './components/common/SCCProductTreeExpander';

jest.mock('@patternfly/react-core', () => ({
  Select: ({ toggle }) => toggle(null),
  Dropdown: ({ toggle }) => toggle(null),
  MenuToggle: ({ ouiaId }) => (
    <div data-testid="toggle" data-ouia-id={ouiaId} />
  ),
  Flex: ({ children }) => <div>{children}</div>,
  FlexItem: ({ children }) => <div>{children}</div>,
  SelectList: 'div',
  SelectOption: 'div',
  DropdownList: 'div',
  TextInputGroup: 'div',
  TextInputGroupMain: 'div',
  TextInputGroupUtilities: 'div',
  Button: 'button',
}));

describe('SCC menu toggle OUIA identifiers', () => {
  it('distinguishes generic selectors by ouiaId', () => {
    const props = {
      selected: '',
      setSelected: () => {},
      inputValue: '',
      setInputValue: () => {},
    };
    const { rerender } = render(
      <GenericSelector {...props} ouiaId="product-" />
    );
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'product-scc-product-picker-toggle'
    );
    rerender(<GenericSelector {...props} ouiaId="architecture-" />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'architecture-scc-product-picker-toggle'
    );
  });

  it('distinguishes repository pickers by product', () => {
    const props = {
      sccProductName: 'Product',
      setSelectedReposFromChild: () => {},
    };
    const { rerender } = render(<SCCRepoPicker {...props} sccProductId={1} />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      '1scc-manager-repo-picker-toggle'
    );
    rerender(<SCCRepoPicker {...props} sccProductId={2} />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      '2scc-manager-repo-picker-toggle'
    );
  });

  it('distinguishes repository views by product', () => {
    const { rerender } = render(<SCCRepoView sccProductId={1} sccRepos={[]} />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      '1scc-manager-repo-view-toggle'
    );
    rerender(<SCCRepoView sccProductId={2} sccRepos={[]} />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      '2scc-manager-repo-view-toggle'
    );
  });

  it('distinguishes generic expanders by ouiaId', () => {
    const props = {
      setInParent: () => {},
      selectOptionOpen: 'open',
      selectOptionClose: 'close',
      initLabel: 'Label',
    };
    const { rerender } = render(
      <SCCGenericExpander {...props} ouiaId="products-" />
    );
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'products-scc-manager-generic-expander-toggle'
    );
    rerender(<SCCGenericExpander {...props} ouiaId="repositories-" />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'repositories-scc-manager-generic-expander-toggle'
    );
  });

  it('distinguishes product tree expanders by caller-provided ouiaId', () => {
    const props = { setExpandAllInParent: () => {} };
    const { rerender } = render(
      <SCCProductTreeExpander {...props} ouiaId="view-" />
    );
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'view-scc-manager-generic-expander-toggle'
    );
    rerender(<SCCProductTreeExpander {...props} ouiaId="picker-" />);
    expect(screen.getByTestId('toggle').getAttribute('data-ouia-id')).toBe(
      'picker-scc-manager-generic-expander-toggle'
    );
  });
});
