import { translate as __ } from 'foremanReact/common/I18n';

export const WARN_DELETE = __(
  'WARNING: If you want to switch SCC accounts and retain the synchronized content, DO NOT delete your old SCC account, even if it is expired. Please change the login and password of your SCC account, instead.\n\nIf you delete your old SCC account, you CANNOT reuse existing repositories, products, content views, and composite content views.\n\n Do you Really want to delete this SCC account %acc_name?'
);

export const INITIAL_DELAY = 5000;
export const MAX_DELAY = 30000;
export const BACKOFF = 1.5;
