require File.expand_path('../fixtures/procs.rb', __FILE__)
require File.expand_path('../../../spec_helper', __FILE__)

describe "Proc.new with an associated block" do
  it "returns a proc that represents the block" do
    Proc.new { }.call.should == nil
    Proc.new { "hello" }.call.should == "hello"
  end
  
  describe "called on a subclass of Proc" do
    before :each do
      @subclass = Class.new(Proc) do
        attr_reader :ok
        def initialize
          @ok = true
          super
        end
      end
    end
    
    it "returns an instance of the subclass" do
      proc = @subclass.new {"hello"}
      
      proc.class.should == @subclass
      proc.call.should == "hello"
      proc.ok.should == true
    end
    
    # JRUBY-5026
    describe "using a reified block parameter" do
      it "returns an instance of the subclass" do
        cls = Class.new do
          def self.subclass=(subclass)
            @subclass = subclass
          end
          def self.foo(&block)
            @subclass.new(&block)
          end
        end
        cls.subclass = @subclass
        proc = cls.foo {"hello"}

        proc.class.should == @subclass
        proc.call.should == "hello"
        proc.ok.should == true
      end
    end
  end

  # This raises a ThreadError on 1.8 HEAD. Reported as bug #1707
  it "raises a LocalJumpError when context of the block no longer exists" do
    def some_method
      Proc.new { return }
    end
    res = some_method()
    
    # Using raise_error here causes 1.9 to hang, so we roll our own
    # begin/rescue block to verify that the exception is raised.

    exception = nil  
    
    begin
      res.call
    rescue LocalJumpError => e
      exception = e
    end

    e.should be_an_instance_of(LocalJumpError)
  end

  it "returns from within enclosing method when 'return' is used in the block" do
    # we essentially verify that the created instance behaves like proc,
    # not like lambda.
    def some_method
      Proc.new { return :proc_return_value }.call
      :method_return_value
    end
    some_method.should == :proc_return_value
  end

end

describe "Proc.new without a block" do
  it "raises an ArgumentError" do
    lambda { Proc.new }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError if invoked from within a method with no block" do
    lambda {
      ProcSpecs.new_proc_in_method
    }.should raise_error(ArgumentError)
  end

  it "returns a new Proc instance from the block passed to the containing method" do
    ProcSpecs.new_proc_in_method { "hello" }.call.should == "hello"
  end

end
