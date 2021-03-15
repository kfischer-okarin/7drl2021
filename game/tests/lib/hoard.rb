module HoardTest
  def self.with_method_replaced(object, method, replacement, &block)
    old_method = object.method(method)
    object.define_singleton_method(method, &replacement)
    block.call
    object.define_singleton_method(method, &old_method)
  end

  class FakeFileSystem
    attr_reader :files

    def initialize(files = nil)
      @files = files || {}
    end

    def read(filename)
      @files[filename]
    end

    def write(filename, content)
      @files[filename] = content
    end
  end
end

def test_hoard_size(args, assert)
  fake_fs = HoardTest::FakeFileSystem.new(
    'data/.index' => ["abc.txt", "another_file.txt"].inspect
  )

  HoardTest.with_method_replaced(args.gtk, :read_file, fake_fs.method(:read)) do
    hoard = Hoard.new('data')
    assert.equal! hoard.size, 2
  end
end

def test_empty_hoard_size(args, assert)
  fake_fs = HoardTest::FakeFileSystem.new

  HoardTest.with_method_replaced(args.gtk, :read_file, fake_fs.method(:read)) do
    hoard = Hoard.new('data')
    assert.equal! hoard.size, 0
  end
end

def test_hoard_access(args, assert)
  fake_fs = HoardTest::FakeFileSystem.new(
    'data/.index' => ["abc.txt"].inspect,
    'data/abc.txt' => {1=>2}.inspect
  )

  HoardTest.with_method_replaced(args.gtk, :read_file, fake_fs.method(:read)) do
    hoard = Hoard.new('data')
    assert.equal! hoard['abc.txt'], { 1 => 2 }
  end
end

def test_hoard_set(args, assert)
  fake_fs = HoardTest::FakeFileSystem.new

  HoardTest.with_method_replaced(args.gtk, :read_file, fake_fs.method(:read)) do
    HoardTest.with_method_replaced(args.gtk, :write_file, fake_fs.method(:write)) do
      hoard = Hoard.new('data')
      hoard['abc.txt'] = { 2 => 3 }

      assert.equal! fake_fs.files, {
        'data/.index' => ['abc.txt'].inspect,
        'data/abc.txt' => { 2 => 3 }.inspect
      }
    end
  end
end

$gtk.reset 100
$gtk.log_level = :off
