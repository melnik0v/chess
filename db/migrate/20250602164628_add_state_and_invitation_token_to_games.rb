class AddStateAndInvitationTokenToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :state, :string
    add_column :games, :invitation_token, :string
  end
end
