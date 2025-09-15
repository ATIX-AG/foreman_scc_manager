/* eslint-disable promise/prefer-await-to-then */
// Configure Enzyme
import { mount, shallow } from 'enzyme';
import React from 'react';
import SCCGenericExpander from './index';

describe('SCCGenericExpander', () => {
  it('renders default properties', () => {
    const wrapper = mount(
      <SCCGenericExpander
        setInParent={() => {}}
        selectOptionOpen="open"
        selectOptionClose="close"
        initLabel="open/close"
      />
    );

    expect(wrapper.find('SCCGenericExpander')).toHaveLength(1);
    expect(wrapper.find('Flex')).toHaveLength(1);
    expect(wrapper.find('FlexItem')).toHaveLength(1);
    expect(wrapper.find('Select')).toHaveLength(1);
  });

  it('passes properties', () => {
    const wrapper = shallow(
      <SCCGenericExpander
        setInParent={() => {}}
        selectOptionOpen="open"
        selectOptionClose="close"
        initLabel="open/close"
      />
    );

    // Select
    const select = wrapper.find('Select');
    expect(select.exists()).toBe(true);
    expect(select.props()).toHaveProperty('selected');
    expect(select.prop('selected')).toContain('open/close');

    // SelectOptions
    const selectOptions = wrapper.find('SelectOption');
    expect(selectOptions).toHaveLength(2);
    const optionValues = selectOptions.map((option) => option.prop('value'));
    expect(optionValues).toContain('open');
    expect(optionValues).toContain('close');
  });
});
