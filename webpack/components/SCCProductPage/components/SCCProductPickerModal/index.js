import React from 'react';
import PropTypes from 'prop-types';
import ForemanModal from 'foremanReact/components/ForemanModal';

import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import {
  Card,
  CardBody,
  TextContent,
  Text,
  TextList,
  TextListItem,
  TextListVariants,
  TextVariants,
} from '@patternfly/react-core';

const generateRepoList = (repoNames, productName) => (
  <>
    <TextListItem key={productName}>{productName}</TextListItem>
    <TextList key={repoNames}>
      {repoNames.map((repo) => (
        <TextListItem key={repo}>{repo}</TextListItem>
      ))}
    </TextList>
  </>
);

const generateProductList = (reposToSubscribe) => (
  <TextList
    key={reposToSubscribe.map((p) => p.productName)}
    component={TextListVariants.ol}
  >
    {reposToSubscribe.map((p) => generateRepoList(p.repoNames, p.productName))}
  </TextList>
);

const SCCProductPickerModal = ({ id, taskId, reposToSubscribe }) => (
  <>
    <ForemanModal
      id={id}
      title={__('Summary of SCC product subscription')}
      enforceFocus
    >
      <Card>
        <CardBody>
          <TextContent key={taskId}>
            <Text key={'modal1'.concat(taskId)}>
              {__('The subscription task with id ')}
              <Text
                key={'modal2'.concat(taskId)}
                component={TextVariants.a}
                target="_blank"
                href={sprintf('/foreman_tasks/tasks/%s', taskId)}
              >
                {sprintf('%s', taskId)}
              </Text>
              {__(' has started successfully.')}
            </Text>
            <Text key={'modal3'.concat(taskId)}>
              {__('The following products will be imported:')}
            </Text>
            {generateProductList(reposToSubscribe)}
          </TextContent>
        </CardBody>
      </Card>
    </ForemanModal>
  </>
);
SCCProductPickerModal.propTypes = {
  id: PropTypes.string,
  taskId: PropTypes.string,
  reposToSubscribe: PropTypes.array,
};

SCCProductPickerModal.defaultProps = {
  id: '',
  taskId: '',
  reposToSubscribe: {},
};

export default SCCProductPickerModal;
