#frozen_string_literal: true

object @scc_account
extends 'api/v2/scc_accounts/base'
attributes :organisation_id, :organisation_name, :login, :password, :base_url, :interval, :sync_date
