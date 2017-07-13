class MakeBinariesByteSizeColumnNotNull < ActiveRecord::Migration
  def change
    change_column_null :binaries, :byte_size, false
  end
end
