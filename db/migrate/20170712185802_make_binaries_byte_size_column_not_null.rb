class MakeBinariesByteSizeColumnNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :binaries, :byte_size, false
  end
end
