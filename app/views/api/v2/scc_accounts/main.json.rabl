# frozen_string_literal: true

object @scc_account
extends 'api/v2/scc_accounts/base'
attributes :organization_id, :organization_name, :login, :base_url, :interval, :download_policy, :mirroring_policy, :sync_date, :katello_gpg_key_id
