import React, { Fragment } from 'react';
import PropTypes from 'prop-types';

import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import {
  Card,
  CardBody,
  Modal,
  TextContent,
  Text,
  TextList,
  TextListItem,
  TextListVariants,
  TextVariants,
} from '@patternfly/react-core';

const generateRepoList = (repoNames, productName) => (
  <Fragment key={productName}>
    <TextListItem key={productName}>{productName}</TextListItem>
    <TextList key={repoNames}>
      {repoNames.map((repo) => (
        <TextListItem key={repo}>{repo}</TextListItem>
      ))}
    </TextList>
  </Fragment>
);

const generateProductList = (reposToSubscribe) => (
  <TextList
    key={reposToSubscribe.map((p) => p.productName)}
    component={TextListVariants.ol}
  >
    {reposToSubscribe.map((p) => generateRepoList(p.repoNames, p.productName))}
  </TextList>
);

const SCCProductPickerModal = ({
  isOpen,
  onClose,
  taskId,
  reposToSubscribe,
}) => (
  <Modal
    ouiaId="scc-product-picker-modal"
    title={__('Summary of SCC product subscription')}
    isOpen={isOpen}
    onClose={onClose}
    variant="medium"
  >
    <Card ouiaId="scc-product-picker-modal-card">
      <CardBody>
        <TextContent key={taskId}>
          <Text
            ouiaId={'scc-subscription-task-message-'.concat(taskId)}
            key={'scc-subscription-task-message-'.concat(taskId)}
          >
            {__('The subscription task with id ')}
            <Text
              ouiaId={'scc-subscription-task-link-'.concat(taskId)}
              key={'scc-subscription-task-link-'.concat(taskId)}
              component={TextVariants.a}
              target="_blank"
              href={sprintf('/foreman_tasks/tasks/%s', taskId)}
            >
              {sprintf('%s', taskId)}
            </Text>
            {__(' has started successfully.')}
          </Text>
          <Text
            ouiaId={'scc-subscription-import-summary-'.concat(taskId)}
            key={'scc-subscription-import-summary-'.concat(taskId)}
          >
            {__('The following products will be imported:')}
          </Text>
          {generateProductList(reposToSubscribe)}
        </TextContent>
      </CardBody>
    </Card>
  </Modal>
);
SCCProductPickerModal.propTypes = {
  isOpen: PropTypes.bool,
  onClose: PropTypes.func,
  taskId: PropTypes.string,
  reposToSubscribe: PropTypes.array,
};

SCCProductPickerModal.defaultProps = {
  isOpen: false,
  onClose: () => {},
  taskId: '',
  reposToSubscribe: [],
};

export default SCCProductPickerModal;
