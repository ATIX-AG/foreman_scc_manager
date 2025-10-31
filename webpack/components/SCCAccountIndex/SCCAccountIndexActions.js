import { APIActions } from 'foremanReact/redux/API';
import { translate as __ } from 'foremanReact/common/I18n';

import { INITIAL_DELAY, MAX_DELAY, BACKOFF } from './SCCAccountIndexConstants';

const isDone = (state, result) =>
  state === 'stopped' || result === 'success' || result === 'error';

const nextDelay = (prevDelay, changed) => {
  const base = changed ? INITIAL_DELAY : prevDelay;
  const next = Math.min(Math.ceil(base * BACKOFF), MAX_DELAY);
  return next;
};

const schedule = (taskTimeoutRef, taskId, ms, fn) => {
  if (taskTimeoutRef.current[taskId])
    clearTimeout(taskTimeoutRef.current[taskId]);
  taskTimeoutRef.current[taskId] = setTimeout(fn, ms);
};

const deriveSyncStatus = (done, result, endedAt, state, fallback) => {
  if (!done) return state || fallback;
  return result === 'success' ? endedAt || __('finished') : __('error');
};

const checkUntilChanged = (
  dispatch,
  taskId,
  accountId,
  setAccounts,
  taskTimeoutRef,
  lastStateRef,
  delay = INITIAL_DELAY
) => {
  if (!taskId) return;

  dispatch(
    APIActions.get({
      key: `task_${taskId}`,
      url: `/foreman_tasks/api/tasks/${taskId}`,
      handleSuccess: (payload) => {
        const task = payload?.data ?? payload;
        const { state, result, ended_at: endedAt } = task || {};
        const prev = lastStateRef.current[accountId];
        const done = isDone(state, result);

        setAccounts((prevState) =>
          prevState.map((acc) => {
            if (acc.id !== accountId) {
              return acc;
            }

            const syncStatus = deriveSyncStatus(
              done,
              result,
              endedAt,
              state,
              acc.sync_status
            );
            return {
              ...acc,
              sync_status: syncStatus,
              sync_task: {
                ...(acc.sync_task || {}),
                id: taskId,
                ended_at: endedAt,
              },
            };
          })
        );

        lastStateRef.current[accountId] = state;

        if (done) {
          if (taskTimeoutRef.current[taskId])
            clearTimeout(taskTimeoutRef.current[taskId]);
          delete taskTimeoutRef.current[taskId];
          delete lastStateRef.current[accountId];
          return;
        }

        const changed = state !== prev;
        const newDelay = nextDelay(delay, changed);

        schedule(taskTimeoutRef, taskId, newDelay, () =>
          checkUntilChanged(
            dispatch,
            taskId,
            accountId,
            setAccounts,
            taskTimeoutRef,
            lastStateRef,
            newDelay
          )
        );
      },
      handleError: () => {
        const newDelay = nextDelay(delay, false);
        schedule(taskTimeoutRef, taskId, newDelay, () =>
          checkUntilChanged(
            dispatch,
            taskId,
            accountId,
            setAccounts,
            taskTimeoutRef,
            lastStateRef,
            newDelay
          )
        );
      },
      errorToast: () => null,
    })
  );
};

export const syncSccAccountAction = (
  dispatch,
  accountId,
  setAccounts,
  taskTimeoutRef,
  lastStateRef
) => {
  if (!accountId) return;

  dispatch(
    APIActions.put({
      key: `syncSccAccount_${accountId}`,
      url: `/api/v2/scc_accounts/${accountId}/sync`,
      successToast: () => __('Sync task started.'),
      errorToast: () => __('Failed to start sync task.'),
      handleSuccess: (resp) => {
        const taskId = resp?.data?.id;
        const initialState = resp?.data?.state || 'planned';

        lastStateRef.current[accountId] = initialState;

        setAccounts((prev) =>
          prev.map((acc) =>
            acc.id === accountId
              ? {
                  ...acc,
                  sync_status: initialState || __('running'),
                }
              : acc
          )
        );

        if (taskTimeoutRef.current[taskId]) {
          clearTimeout(taskTimeoutRef.current[taskId]);
        }
        taskTimeoutRef.current[taskId] = setTimeout(() => {
          checkUntilChanged(
            dispatch,
            taskId,
            accountId,
            setAccounts,
            taskTimeoutRef,
            lastStateRef
          );
        }, 15000);
      },
      handleError: () => {
        setAccounts((prev) =>
          prev.map((acc) =>
            acc.id === accountId
              ? {
                  ...acc,
                  sync_status: __('error'),
                  taskId: null,
                }
              : acc
          )
        );
      },
    })
  );
};

export const deleteSccAccountAction = (
  dispatch,
  id,
  setAccounts,
  setDeleteOpen,
  deletingIdRef
) => {
  if (!id) return;

  dispatch(
    APIActions.delete({
      key: `deleteSccAccount_${id}`,
      url: `/api/v2/scc_accounts/${id}`,
      successToast: () => __('SCC account deleted successfully.'),
      errorToast: () => __('Failed to delete SCC account.'),
      handleSuccess: () => {
        setAccounts((prev) => prev.filter((acc) => acc.id !== id));
        setDeleteOpen(false);
        deletingIdRef.current = null;
      },
      handleError: () => {
        setDeleteOpen(false);
        deletingIdRef.current = null;
      },
    })
  );
};
