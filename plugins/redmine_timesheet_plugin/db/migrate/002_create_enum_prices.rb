class CreateEnumPrices < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.references :enumerations
      t.float :price
    end
    add_index :prices, :enumerations_id
  end
end
