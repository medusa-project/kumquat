require 'test_helper'

class IiifImageConverterTest < ActiveSupport::TestCase

  setup do
    @instance = IiifImageConverter.new
  end

  # convert_binary()

  test 'convert_binary()' do
    Dir.mktmpdir do |tmpdir|
      binary = binaries(:sanborn_obj1_page1_access)
      format = 'png'

      pathname = @instance.convert_binary(binary, tmpdir, format)

      assert_equal tmpdir + binary.repository_relative_pathname.split('.')[0...-1].join('.') +
                       '.' + format,
                   pathname
      assert File.size(pathname) > 100000
    end
  end

  # convert_images()

  test 'convert_images() with compound object' do
    Dir.mktmpdir do |tmpdir|
      item = items(:sanborn_obj1)
      format = 'png'

      @instance.convert_images(item, tmpdir, format)

      inodes = Dir.glob(tmpdir + '/**')

      assert_equal 1, inodes.length
    end
  end

  test 'convert_images() with compound object page' do
    Dir.mktmpdir do |tmpdir|
      item = items(:sanborn_obj1_page1)
      format = 'png'

      @instance.convert_images(item, tmpdir, format)

      inodes = Dir.glob(tmpdir + '/**')

      assert_equal 1, inodes.length
    end
  end

  test 'convert_images() with directory-variant' do
    Dir.mktmpdir do |tmpdir|
      item = items(:illini_union_dir1)
      format = 'png'

      @instance.convert_images(item, tmpdir, format)

      inodes = Dir.glob(tmpdir + '/**')

      assert_equal 1, inodes.length
    end
  end

  test 'convert_images() with file-variant' do
    Dir.mktmpdir do |tmpdir|
      item = items(:illini_union_dir1_file1)
      format = 'png'

      @instance.convert_images(item, tmpdir, format)

      inodes = Dir.glob(tmpdir + '/**')

      assert_equal 1, inodes.length
    end
  end

end
