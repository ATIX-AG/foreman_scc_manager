class SccKatelloRepository < ApplicationRecord
  belongs_to :scc_repository
  belongs_to :katello_root_repository, class_name: 'Katello::RootRepository'
end
