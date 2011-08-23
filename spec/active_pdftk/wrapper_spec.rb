require 'spec_helper'

inputs = [:path, :hash, :file, :tempfile, :stringio]
outputs = [:path, :file, :tempfile, :stringio, :nil]

def get_input(input_type)
  case input_type
  when :path
    path_to_pdf('fields.pdf')
  when :hash
    {path_to_pdf('fields.pdf') => nil}
  when :file
    File.new(path_to_pdf('fields.pdf'))
  when :tempfile
    t = Tempfile.new('specs')
    t.write(File.read(path_to_pdf('fields.pdf')))
    t
  when :stringio
    StringIO.new(File.read(path_to_pdf('fields.pdf')))
  end
end

def get_output(output_type)
  case output_type
  when :path
    path_to_pdf('output.spec')
  when :file
    File.new(path_to_pdf('output.spec'), 'w+')
  when :tempfile
    Tempfile.new('specs2')
  when :stringio
    StringIO.new()
  when :nil
    nil
  end
end

describe ActivePdftk::Wrapper do
  before(:all) { @pdftk = ActivePdftk::Wrapper.new }

  context "new" do
    it "should instantiate the object." do
      @pdftk.should be_an_instance_of(ActivePdftk::Wrapper)
    end

    it "should pass the defaults statements to the call instance." do
      path = ActivePdftk::Call.new.locate_pdftk
      @pdftk_opt = ActivePdftk::Wrapper.new(:path => path, :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
      @pdftk_opt.default_statements.should == {:path => path, :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}}
    end
  end



  shared_examples "a working command" do
    it "should return a #{@output.nil? ? StringIO : @output.class}" do
      @call_output.should be_kind_of(@output.nil? ? StringIO : @output.class)
    end

    it "should return expected data" do
      if @call_output.is_a? String
        File.new(@call_output).read.should == @example_expect
      else
        @call_output.rewind
        @call_output.read.should == @example_expect
      end
    end

    after(:each) do
      if @call_output.is_a?(String)
        File.unlink(@call_output)
      elsif @call_output.is_a?(File)
        File.unlink(@call_output.path)
      end
    end
  end

  inputs.each do |input_type|
    outputs.each do |output_type|
      context "(Input:#{input_type}|Output:#{output_type})" do
        before :each do
          @input = get_input(input_type)
          @input.rewind rescue nil # rewind if possible.
          @output = get_output(output_type)
        end

        describe "#dump_data_fields" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.data_fields')).read }
            before(:each) { @call_output = @pdftk.dump_data_fields(@input, :output => @output) }
          end
        end

        describe "#generate_fdf" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.fdf')).read }
            before(:each) { @call_output = @pdftk.generate_fdf(@input,:output => @output) }
          end
        end

        describe "#dump_data" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.data')).read }
            before(:each) { @call_output = @pdftk.dump_data(@input,:output => @output) }
          end
        end

        describe "#attach_file", :unless => output_type == :nil  do
          it_behaves_like "a working command"do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.attach')).read }
            before(:each) { @call_output = @pdftk.attach_files(@input, [path_to_pdf('fields.data'), path_to_pdf('fields.fdf')], :output => @output) }
          end
        end

        #cat (partially supported)
        #shuffle (partially supported)
        #burst (fully supported)
        #
        #fill_form (fully supported)
        #background (fully supported)
        #multibackground (fully supported)
        #stamp (fully supported)
        #multistamp (fully supported)
        #
        #update_info (fully supported)
        #update_info_utf8 (fully supported)
        #unpack_files (fully supported)

      end

      #context "fill_form" do
      #  it "should fill the field of the pdf" do
      #    @pdftk.fill_form(path_to_pdf('fields.pdf'), {'text_not_required' => 'Running specs'}, :output => path_to_pdf('filled_spec.pdf'))
      #    temp = @pdftk.dump_data_fields(path_to_pdf('filled_spec.pdf'))
      #    temp.rewind
      #    temp.read.should match(/FieldValue: Running specs/)
      #    File.unlink(path_to_pdf('filled_spec.pdf')).should == 1
      #  end
      #end
      #
      #context "update_info" do
      #  it "should update file info of the pdf" do
      #    @s_info = @pdftk.dump_data(path_to_pdf('fields.pdf'))
      #    @s_info.string = @s_info.string.gsub('InfoValue: Untitled', 'InfoValue: Data Updated')
      #    @pdftk.update_info(path_to_pdf('fields.pdf'), @s_info, :output => @s_out = StringIO.new)
      #    @s_out.rewind
      #    @pdftk.dump_data(@s_out).string.should == @s_info.string
      #  end
      #end
      #
      #context "attach_files/unpack_files" do
      #  it "should bind the file ine the pdf" do
      #    @pdftk.attach_files(path_to_pdf('fields.pdf'), path_to_pdf('attached_file.txt'), :output => path_to_pdf('fields.pdf.attached'))
      #    File.unlink(path_to_pdf('attached_file.txt')).should == 1
      #  end
      #
      #  it "should retrieve the file" do
      #    @pdftk.unpack_files(path_to_pdf('fields.pdf.attached'), path_to_pdf(''))
      #    File.unlink(path_to_pdf('fields.pdf.attached')).should == 1
      #  end
      #end
      #
      #context "burst" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('fields.pdf'), :operation => :burst})
      #    @pdftk.burst(path_to_pdf('fields.pdf'))
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('fields.pdf'), :operation => :burst, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :options => {:encrypt  => :'40bit'})
      #  end
      #
      #  it "should put a file in the system tmpdir when no output location given" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'))
      #    File.unlink(File.join(Dir.tmpdir, 'pg_0001.pdf')).should == 1
      #  end
      #
      #  it "should put a file in the system tmpdir when no output location given but a page name format given" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :output => 'page_%02d.pdf')
      #    File.unlink(File.join(Dir.tmpdir, 'page_01.pdf')).should == 1
      #  end
      #
      #  it "should put a file in the specified path" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :output => path_to_pdf('page_%02d.pdf').to_s)
      #    File.unlink(path_to_pdf('page_01.pdf')).should == 1
      #  end
      #end
      #
      #context "background" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:background => path_to_pdf('b.pdf')}})
      #    @pdftk.background(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'))
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:background => path_to_pdf('b.pdf')}, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.background(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :options => {:encrypt  => :'40bit'})
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.background(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :output => path_to_pdf('background.pdf'))
      #    File.unlink(path_to_pdf('background.pdf')).should == 1
      #  end
      #end
      #
      #context "multibackground" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:multibackground => path_to_pdf('b.pdf')}})
      #    @pdftk.background(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :multi => true)
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:multibackground => path_to_pdf('b.pdf')}, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.background(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :multi => true, :options => {:encrypt  => :'40bit'})
      #  end
      #end
      #
      #context "stamp" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:stamp => path_to_pdf('b.pdf')}})
      #    @pdftk.stamp(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'))
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:stamp => path_to_pdf('b.pdf')}, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.stamp(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :options => {:encrypt  => :'40bit'})
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.stamp(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :output => path_to_pdf('stamp.pdf'))
      #    File.unlink(path_to_pdf('stamp.pdf')).should == 1
      #  end
      #end
      #
      #context "multistamp" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:multistamp => path_to_pdf('b.pdf')}})
      #    @pdftk.stamp(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :multi => true)
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('a.pdf'), :operation => {:multistamp => path_to_pdf('b.pdf')}, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.stamp(path_to_pdf('a.pdf'), path_to_pdf('b.pdf'), :multi => true, :options => {:encrypt  => :'40bit'})
      #  end
      #end
      #
      #context "cat" do
      #  it "should call #pdftk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      #    @pdftk.cat([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.cat([{:pdf => path_to_pdf('a.pdf'), :pass => 'foo'}, {:pdf => path_to_pdf('b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => path_to_pdf('cat.pdf'))
      #    File.unlink(path_to_pdf('cat.pdf')).should == 1
      #  end
      #end
      #
      #context "shuffle" do
      #  it "should call #pdftk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:shuffle => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      #    @pdftk.shuffle([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.shuffle([{:pdf => path_to_pdf('a.pdf'), :pass => 'foo'}, {:pdf => path_to_pdf('b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => path_to_pdf('shuffle.pdf'))
      #    File.unlink(path_to_pdf('shuffle.pdf')).should == 1
      #  end
      #end
      #
      #context "unpack_files" do
      #  it "should return Dir.tmpdir" do
      #    @pdftk.attach_files(path_to_pdf('fields.pdf'), [path_to_pdf('attached_file.txt')], :output => path_to_pdf('attached.pdf'))
      #    @pdftk.unpack_files(path_to_pdf('attached.pdf')).should == Dir.tmpdir
      #    File.unlink(path_to_pdf('attached.pdf')).should == 1
      #  end
      #
      #  it "should return the specified output directory" do
      #    @pdftk.attach_files(path_to_pdf('fields.pdf'), [path_to_pdf('attached_file.txt')], :output => path_to_pdf('attached.pdf'))
      #    @pdftk.unpack_files(path_to_pdf('attached.pdf'), path_to_pdf(nil)).should == path_to_pdf(nil)
      #    File.unlink(path_to_pdf('attached.pdf')).should == 1
      #  end
      #end

    end # each outputs
  end # each inputs
end # Wrapper
